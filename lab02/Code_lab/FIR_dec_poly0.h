// Decimation/interpolation polyphase filter coefficients
#define M_DEC_INT 5
#define N_DEC_DELAYS 6
#define N_DEC_INT 30
short H_Delay0_DEC[6];
short H_Delay0_INT[6];
short b_FIR_dec_Poly0[6]={
    -70,   -115,    550,   6500,   -521,    160,
};

