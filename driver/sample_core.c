// ---------------------------------------------------------------------------------------
// Copyright (c) 2024 john_tito All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ---------------------------------------------------------------------------------------

#include "sample_core.h"
#include "xil_io.h"
#include <stdlib.h>
#include <math.h>

int sample_init(sample_core_t **dev_ptr, uint32_t base_addr, uint32_t bytes_per_sample)
{
    if (dev_ptr == NULL)
        return -1;

    *dev_ptr = NULL;
    sample_core_t *dev = (sample_core_t *)calloc(1, sizeof(sample_core_t));
    if (NULL == dev)
        return -2;

    dev->baseaddr = base_addr;

    // soft reset
    dev->ctrl.reset = 1;
    Xil_Out32(dev->baseaddr + offsetof(sample_core_t, ctrl), dev->ctrl.all);

    // read write test
    {
        Xil_Out32(dev->baseaddr + offsetof(sample_core_t, test), 0x55555555);
        dev->test = Xil_In32(dev->baseaddr + offsetof(sample_core_t, test));

        if (dev->test != 0x55555555)
            return -4;

        Xil_Out32(dev->baseaddr + offsetof(sample_core_t, test), 0xAAAAAAAA);
        dev->test = Xil_In32(dev->baseaddr + offsetof(sample_core_t, test));

        if (dev->test != 0xAAAAAAAA)
            return -4;
    }

    // read instance info
    {
        dev->id = Xil_In32(dev->baseaddr + offsetof(sample_core_t, id));

        if (dev->id != 0xF7DEC7A5)
            return -3;

        dev->revision = Xil_In32(dev->baseaddr + offsetof(sample_core_t, revision));
        dev->buildtime = Xil_In32(dev->baseaddr + offsetof(sample_core_t, buildtime));
        dev->bytes_per_symbol = Xil_In32(dev->baseaddr + offsetof(sample_core_t, bytes_per_symbol));
        dev->bytes_per_sample = bytes_per_sample;

        dev->samples_per_symbol = dev->bytes_per_symbol / dev->bytes_per_sample;
    }

    *dev_ptr = dev;

    return 0;
}

int sample_deinit(sample_core_t **dev_ptr)
{
    if (dev_ptr == NULL)
        return -1;

    free(*dev_ptr);
    *dev_ptr = NULL;

    return 0;
}

int sample_start(sample_core_t *dev, uint32_t blocks, uint32_t samplePts, uint32_t preSamplePts)
{
    if (dev == NULL)
        return -1;

    if (samplePts == 0)
        return -2;

    uint32_t timeout = 0;

    while (1)
    {
        Xil_Out32(dev->baseaddr + offsetof(sample_core_t, state), 0xFFFFFFFF);
        dev->state.all = Xil_In32(dev->baseaddr + offsetof(sample_core_t, state));
        if ((timeout > 5))
            return -3;
        else if (dev->state.all == 0)
            break;
        else
            timeout = timeout + 1;
        // sleep(1);
    }

    uint32_t symbol_num = ceil(samplePts / dev->samples_per_symbol);

    if (symbol_num <= 0)
    	symbol_num = 1;

    uint32_t sample_num = symbol_num * dev->samples_per_symbol;
    uint32_t post_sample_num = samplePts - preSamplePts;
    uint32_t pre_sample_num = sample_num - post_sample_num;

    Xil_Out32(dev->baseaddr + offsetof(sample_core_t, block_num), blocks);
    Xil_Out32(dev->baseaddr + offsetof(sample_core_t, pre_sample_num), pre_sample_num);
    Xil_Out32(dev->baseaddr + offsetof(sample_core_t, post_sample_num), post_sample_num);

    dev->ctrl.all = 0;
    dev->ctrl.update = 1;
    Xil_Out32(dev->baseaddr + offsetof(sample_core_t, ctrl), dev->ctrl.all);
    dev->state.all = Xil_In32(dev->baseaddr + offsetof(sample_core_t, state));
    return 0;
}

int sample_get_state(sample_core_t *dev, uint32_t *state)
{
    if (dev == NULL)
        return -1;

    uint32_t timeout = 0;
    uint32_t left_cnt = 0;

    while (1)
    {
        dev->state.all = Xil_In32(dev->baseaddr + offsetof(sample_core_t, state));
        left_cnt = Xil_In32(dev->baseaddr + offsetof(sample_core_t, sts_block_num));
        if ((timeout > 5))
        {
            *state = 0;
            break;
        }
        else if (dev->state.done)
        {
            if (!left_cnt && !dev->state.busy)
            {
                *state = 1;
                break;
            }
            else
            {
                *state = 2;
                break;
            }
        }

        // sleep(1);
        timeout = timeout + 1;
    }

    return 0;
}
