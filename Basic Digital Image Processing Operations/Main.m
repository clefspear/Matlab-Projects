%%1%%
I=imread('Flooded_house.jpg');
imshow(I); %shows image%

% % rows and columns in the image
% r = size(I, 1);
% c = size(I, 2);
%   
% % creating zero matrices
% R = zeros(r, c, 3);
% G = zeros(r, c, 3);
% B = zeros(r, c, 3);
% 
% %%2%%
% R(:, :, 1) = I(:, :, 1);
% title('Red');
% G(:, :, 2) = I(:, :, 2);
% title('Green');
% B(:, :, 3) = I(:, :, 3);
% title('Blue');
% figure, imshow(uint8(R));
% figure, imshow(uint8(G));
% figure, imshow(uint8(B));
% 
%%3%%
% YCBCR = rgb2ycbcr(I); %from RBG to YCRCB
% figure, imshow(YCBCR);
% title('YCBCR');
% 
% RGB=ycbcr2rgb(YCBCR);  %%from YCRCB to RGB
% figure, imshow(RGB);
% title('YCBCR to RGB');
%  
%%4%%
%Isolate Y. 
Y = YCBCR(:,:,1);
figure, imshow(Y);
title('Y');
%Isolate Cb. 
Cb = YCBCR(:,:,2);
figure, imshow(Cb);
title('Cb');
%Isolate Cr. 
Cr= YCBCR(:,:,3);
figure, imshow(Cr);
title('Cr');
% %%5%%
% Crsub=YCBCR(1:2:480,1:2:640,3);
% figure, imshow(Crsub);
% title('4:2:0 Cr Component');
% Cbsub=YCBCR(1:2:480,1:2:640,2);
% figure, imshow(Cbsub);
% title('4:2:0 Cb Component');
%6%%
Cbup = Cb;
Cbup(1:2:480, 2:2:640) = 0;

Crup=Cr;
Crup(1:2:480, 2:2:640) = 0;

Cbup(1:2:480,1:2:640) = Cbsub(:,:); 
Crup(1:2:480,1:2:640) = Crsub(:,:);

Cbup(1:2:479,2:2:638) = (double(Cbup(1:2:480,1:2:638))+ double(Cbup(1:2:480,3:2:639)))/2;
Cbup(1:2:479,640) = Cbup(1:2:479,639);
 
Cbup(2:2:478,:) = (double(Cbup(1:2:477,:)) + double(Cbup(3:2:479,:)))/2;
Cbup(480,:) = Cbup(479,:);

Crup(1:2:479,2:2:638) = (double(Crup(1:2:480,1:2:637))+ double(Crup(1:2:480,3:2:639)))/2;
Crup(1:2:479,640) = Crup(1:2:479,639);
 
Crup(2:2:478,:) = (double(Crup(1:2:477,:)) + double(Crup(3:2:479,:)))/2;
Crup(480,:) = Crup(479,:);

figure, imshow(Cbup);
title('Cb Linear Interpolation upsampling');

figure, imshow(Crup);
title('Cr Linear Interpolation upsampling');

Cbup2 = Cb;   
Cbup2(1:2:480,2:2:640) = 0;

Crup2 = Cr;   
Crup2(1:2:480,2:2:640) = 0;

% replicating pixels from subsampling
Cbup2(1:2:479,2:2:640) = Cbup2(1:2:479,1:2:639);
Cbup2(2:2:480,:) = Cbup2(1:2:479,:);

Crup2(1:2:479,2:2:640) = Crup2(1:2:479,1:2:639);
Crup2(2:2:480,:) = Crup2(1:2:479,:);

figure, imshow(Cbup2);
title('Simple replication of Cb Upsample');

figure, imshow(Cbup2);
title('Simple replication of Cr Upsample');


%%getting results from linear interpolation and make new 3d array
YCbCr1(:,:,1) = Y;
YCbCr1(:,:,2) = Cbup;
YCbCr1(:,:,3) = Crup;

RGB1 = ycbcr2rgb(YCbCr1); %convert to rgb


%%getting results from simple replication and make new 3d array
YCbCr2(:,:,1) = Y;
YCbCr2(:,:,2) = Cbup2;
YCbCr2(:,:,3) = Crup2;

RGB2 = ycbcr2rgb(YCbCr2);%convert to rgb

%step 8 display the original and reconstructed images 
%%we use  the subplot
figure, imshow(RGB);
title('RGB Image-original');

figure, imshow(RGB1);
title(' Linear Interpolation Upsampling using RGB');

figure, imshow(RGB2);
title(' Simple replication using RGB');

%%step 10
%Calculate the MSE


double MSEcr;
double MSEcb;
        
%%doing the work for the MSE%%
CB = (double(Cbup(:,:)) - double(Cb(:,:))).^2;
CR = (double(Crup(:,:)) - double(Cr(:,:))).^2;
MSEcb = sum(CB(:))/ (640 * 480);
MSEcr = sum(CR(:))/ (640 * 480);

%Display the result of Cb and Cr:
disp('The MSE of Cr is ');
disp(MSEcr); 
disp('The MSE of Cb is ');
disp(MSEcb);












