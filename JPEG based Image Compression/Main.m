%% read and displaying the image
imfinfo('Flooded_house.jpg')
RGBpic = imread('Flooded_house.jpg','jpg');
 YCbCr = rgb2ycbcr(RGBpic); %% convert the image into ycbcr
 
 %%components of Y,Cb,Cr
 Ycomp=YCbCr(:,:,1);
Cbcomp=YCbCr(:,:,2);
Crcomp=YCbCr(:,:,3);
 
%%Step A
%%subsample of ycbcr 4:2:0
 Crsub=YCbCr(1:2:536,1:2:704,3);
Cbsub=YCbCr(1:2:536,1:2:704,2);

%%DCT for Y,Cb,Cr
pDCT = @dct2;  
YDCT = blkproc (Ycomp, [8 8], pDCT);
CBDCT = blkproc (Cbsub, [8 8], pDCT);
CRDCT = blkproc (Crsub, [8 8], pDCT);

%round off
YDCT = fix(YDCT);
  ydctblock=YDCT(49:56,1:16); %%display the 1st and 2nd blocks of 6th row
 
figure(1)
imshow(ydctblock),title('DCT  image of 1st and 2nd blocks of 6th row');
disp('DCT coefficient matrix for 1st and 2nd blocks of 6th row');
disp(ydctblock);

%% Step B
% the quantization matrix for luminance from lecture
lumin_matrix = [16 11 10 16 24 40 51 61;12 12 14 19 26 58 60 55;14 13 16 24 40 57 69 56;
14 17 22 29 51 87 89 62;18 22 37 56 68 109 103 77;24 35 55 64 81 104 113 92;
49 64 78 87 108 121 120 101;72 92 95 98 112 100 103 99];

% the quantization marix for chromiance from lecture
chrome_matrix = [17 18 24 47 99 99 99 99;18 21 26 66 99 99 99 99;24 26 56 99 99 99 99 99;
47 66 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99;
99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99];

%%performing quantization for the Y and CB and Cr componenets of image
YDCT2=YDCT;
CBDCT2 = CBDCT;
CRDCT2 = CRDCT;

lum=@(YDCT2)round(YDCT2./lumin_matrix);
luminDCT = blkproc(YDCT2,[8 8],lum);

chrom1=@(CBDCT2) round(CBDCT2./chrome_matrix);
chDCT1 = blkproc(CBDCT2,[8 8],chrom1);

chrom2=@(CRDCT2) round(CRDCT2./chrome_matrix);
chDCT2 = blkproc(CRDCT2,[8 8],chrom2);

qY=luminDCT(49:56,1:16);
qCB=chDCT1(49:56,1:16);
qCR=chDCT2(49:56,1:16);
disp('The DC DCT coefficient of Y is ');
disp(qY(1,1));

zigY=zigzag1(qY); %%code for zigzag1 is at the bottom starting at line 157
disp('The zigzag DCT coefficient of Y is ');
disp(zigY);

%%Step C inverse quantization
lumin2 = luminDCT;
cb=chDCT1;
cr=chDCT2;

ylum= @(lumin2)round(lumin2.*lumin_matrix);
lumy=blkproc(luminDCT,[8 8],ylum);

cbchr= @(cb)round(cb.*chrome_matrix);
chrcb=blkproc(chDCT1,[8 8],cbchr);

crchr= @(cr)round(cr.*chrome_matrix);
chrcr=blkproc(chDCT2,[8 8],crchr);



%% step D inverse dct

p=@idct2;
yidct=blkproc(lumy,[8 8],p);
cbidct=blkproc(chrcb,[8 8],p);
cridct=blkproc(chrcr,[8 8],p);

yidct=uint8(yidct);
cbidct=uint8(cbidct);
cridct=uint8(cridct);

%%linear interpolation
Cbidctcpy = cbidct;   
Cbidctcpy(1:2:536,2:2:704) = 0;

Cridctcpy = cridct;   
Cridctcpy(1:2:536,2:2:704) = 0;


Cbidctcpy(1:2:536,1:2:704) = Cbsub(:,:); 
Cridctcpy(1:2:536,1:2:704) = Crsub(:,:);

 %calculating the average value of 2 neighbor pixels for the Cb and Cr bads
Cbidctcpy(1:2:535,2:2:702) = (double(Cbidctcpy(1:2:536,1:2:702))+ double(Cbidctcpy(1:2:536,3:2:703)))/2;
Cbidctcpy(1:2:535,704) = Cbidctcpy(1:2:535,703);
 
Cbidctcpy(2:2:534,:) = (double(Cbidctcpy(1:2:533,:)) + double(Cbidctcpy(3:2:535,:)))/2;
Cbidctcpy(536,:) = Cbidctcpy(535,:);

Cridctcpy(1:2:535,2:2:702) = (double(Cridctcpy(1:2:536,1:2:701))+ double(Cridctcpy(1:2:536,3:2:703)))/2;
Cridctcpy(1:2:535,704) = Cridctcpy(1:2:535,703);
 
Cridctcpy(2:2:534,:) = (double(Cridctcpy(1:2:533,:)) + double(Cridctcpy(3:2:535,:)))/2;
Cridctcpy(536,:) = Cridctcpy(535,:);
%%end of linear interpolation

%%getting results from linear interpolation and make new 3d array
YCbCr1(:,:,1) = yidct;
YCbCr1(:,:,2) = Cbidctcpy;
YCbCr1(:,:,3) = Cridctcpy;

RGB1 = ycbcr2rgb(YCbCr1); %convert to rgb

%%displaying the linear interpolation vs the original image
figure(2)
subplot(1,2,1)
imshow(RGBpic),
title('Original Image');
subplot(1,2,2)
imshow(RGB1),
title('Linear interpolation');

%%calculating the error
error= Ycomp-yidct;  %% ycomp is the orignal imagen of the Y component, yidct is the reconstructed one of the Y component

figure(3)
imshow(error),
title('Error Image');
s1=sum(error(:).^2)/(704*536); %%sum of MSE of Y
PSNRY=10 *log10(255^2/s1); %%PSNR of the Y Component
disp('The PSNR of Y is ');
disp(PSNRY);




%%code for zigzag
function out1=zigzag1(in1)

[numrows,numcols]=size(in1);

out1=zeros(1,numrows*numcols);  %initialization for the output vector 

currow=1;	
curcol=1;	
curindex=1;

while currow<=numrows && curcol<=numcols
    
    %go right at the top
	if currow==1 && mod(currow+curcol,2)==0 && curcol~=numcols
		out1(curindex)=in1(currow,curcol);
		curcol=curcol+1;							
		curindex=curindex+1;
        
		%go right at the bottom
    elseif currow==numrows && mod(currow+curcol,2)~=0 && curcol~=numcols
		out1(curindex)=in1(currow,curcol);
		curcol=curcol+1;							
		curindex=curindex+1;
		
        %go down at the left
        elseif curcol==1 && mod(currow+curcol,2)~=0 && currow~=numrows
		out1(curindex)=in1(currow,curcol);
		currow=currow+1;							
		curindex=curindex+1;
		
        %go down at the right
            elseif curcol==numcols && mod(currow+curcol,2)==0 && currow~=numrows
		out1(curindex)=in1(currow,curcol);
		currow=currow+1;							
		curindex=curindex+1;
		
        %go diagonally left down
              elseif curcol~=1 && currow~=numrows && mod(currow+curcol,2)~=0
		out1(curindex)=in1(currow,curcol);
		currow=currow+1;		
        curcol=curcol-1;	
		curindex=curindex+1;
		
        %go diagonally right up
             elseif currow~=1 && curcol~=numcols && mod(currow+curcol,2)==0
		out1(curindex)=in1(currow,curcol);
		currow=currow-1;		
        curcol=curcol+1;	
		curindex=curindex+1;
		
             elseif currow==numrows && curcol==numcols	%out here bottom right element is being obtained
        out1(end)=in1(end);							%here is the end of the operation
		break										
end
end
end