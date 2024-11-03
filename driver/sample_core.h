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

/**
 * @file sample_core.h
 * @brief
 * @author
 */

#ifndef _SAMPLE_CORE_H_
#define _SAMPLE_CORE_H_

#ifdef __cplusplus
extern "C"
{
#endif

    /******************************************************************************/
    /************************ Include Files ***************************************/
    /******************************************************************************/

#include <stdbool.h>
#include <stdint.h>

    /******************************************************************************/
    /************************ Marco Definitions ***********************************/
    /******************************************************************************/

    /******************************************************************************/
    /************************ Types Definitions ***********************************/
    /******************************************************************************/

    typedef union sample_ctrl_t
    {
        struct
        {
            uint32_t update : 1; // bit 0
            uint32_t : 30;       // bit 1:30
            uint32_t reset : 1; // bit 31
        };
        uint32_t all;
    } sample_ctrl_t;

    typedef union sample_status_t
    {
        struct
        {
            uint32_t done : 1; // bit 0
            uint32_t busy : 1; // bit 1
            uint32_t : 30;     // bit 2:31
        };
        uint32_t all;
    } sample_status_t;

    typedef struct sample_core_t
    {
        uint32_t id;               // 0x0000, RO
        uint32_t revision;         // 0x0004, RO
        uint32_t buildtime;        // 0x0008, RO
        uint32_t test;             // 0x000C, RW
        uint32_t bytes_per_symbol; // 0x0010, RO
        sample_ctrl_t ctrl;        // 0x0014, RW
        sample_status_t state;     // 0x0018, RW
        uint32_t block_num;        // 0x002C, RW
        uint32_t pre_sample_num;   // 0x0020, RW
        uint32_t post_sample_num;  // 0x0024, RW
        uint32_t sts_block_num;    // 0x0028, RO
        uint32_t baseaddr;
        uint32_t bytes_per_sample;
        uint32_t samples_per_symbol;
    } sample_core_t;

    /******************************************************************************/
    /************************ Functions Declarations ******************************/
    /******************************************************************************/

    extern int sample_init(sample_core_t **dev_ptr, uint32_t base_addr, uint32_t bytes_per_sample);
    extern int sample_deinit(sample_core_t **dev_ptr);

    extern int sample_start(sample_core_t *dev, uint32_t blocks, uint32_t samplePts, uint32_t preSamplePts);
    extern int sample_get_state(sample_core_t *dev, uint32_t *state);

    /******************************************************************************/
    /************************ Variable Declarations *******************************/
    /******************************************************************************/

#ifdef __cplusplus
}
#endif

#endif // _SAMPLE_CORE_H_
