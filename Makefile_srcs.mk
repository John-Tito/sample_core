
VVP_INCLUDEDIR=
VVP_INCLUDEDIR+=-I ./src/
VVP_INCLUDEDIR+=-I ./sim/

VVP_CFLAGS=
VVP_CFLAGS+=-g2005-sv

VVP_SRCS=
VVP_SRCS+= ./src/sample_core.v

VVP_SRCS+= ./sim/sample_core_tb.v
# VVP_SRCS+= ./sim/multi_block_ctrl_tb.v