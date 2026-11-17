// Decimation/interpolation polyphase filter coefficients
#define M_DEC_INT 5
#define N_DEC_INT 30

// Polyphase 1
short H_filt_FIR_phase_1[6] = {-70, -115, 550, 6500, -521, 160, };

// Polyphase 2
short H_filt_FIR_phase_2[6] = {122, -519, 2154, 5570, -963, 252, };

// Polyphase 3
short H_filt_FIR_phase_3[6] = {207, -884, 3977, 3977, -884, 207, };

// Polyphase 4
short H_filt_FIR_phase_4[6] = {252, -963, 5570, 2154, -519, 122, };

// Polyphase 5
short H_filt_FIR_phase_5[6] = {160, -521, 6500, 550, -115, -70, };
