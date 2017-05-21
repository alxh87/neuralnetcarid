# neuralnetcarid
Neural network for car numberplate identification

Use Matlab with Image Processing Toolbox and Computer Vision System Toolbox

Image to CSV : Select Image(s), then it displays detected letters. Type letters shown, then press ‘Save to CSV’ button. It will accumulate data of letters into ‘Letter_?.csv’. (each line is one of data in 1-by-360 matrix - corresponding 20-by-18 image matrix)

Training and Validation : It uses both Training_CSV and Validation_CSV. It performs 2,000 cycles of training with validation on every 50 cycles. Final weight matrices w and wb will be stored into Matrix_W.csv and Matrix_WB.csv. It is needed to use for next testing.

Testing : Similar UI with Image to CSV. Select Image(s), then it displays detected letters and recognized results. To apply updated weight vectors. Copy both Matrix_W.csv and Matrix_WB.csv from above then replace them with previous.
	

