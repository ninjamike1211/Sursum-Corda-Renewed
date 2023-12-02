
#define Local_Size_X 16
#define Local_Size_Y 16

#define Min_Log_Lum (-2.0)
#define Max_Log_Lum 20.0

#define Exposure_Scale 1.0

const int Local_Bin_Count = Local_Size_X * Local_Size_Y;
const float Local_Bin_Size_Positive = float(Local_Bin_Count - 2);

const float Log_Lum_Range = abs(Max_Log_Lum - Min_Log_Lum);
const float Inv_Log_Lum_Range = 1.0 / (Log_Lum_Range);

layout(std430, binding = 0) buffer Histogram {
    uint HistogramGlobal[Local_Bin_Count];
    float averageLum;
};