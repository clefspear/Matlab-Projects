clear all;
clc;

% Reading the sequence of someone walking.
v_obj = VideoReader('walk_qcif.avi');
i = 0;
j = 1;
width = v_obj.Width;
height = v_obj.Height;
fprintf("Dimensions of the Video sequence: [height*width]:[%d x %d]\n",height,width);
% extracting every frame from the given video sequence and coverting each
% extracted frame to ycbcr.
while hasFrame(v_obj)
    v_frm(j).cdata = readFrame(v_obj);
    ycbcr = rgb2ycbcr(v_frm(j).cdata(:,:,:));
    y(:,:,j) = ycbcr(:,:,1);
    cb(:,:,j) = ycbcr(1:2:end,1:2:end,2);
    cr(:,:,j) = ycbcr(1:2:end,1:2:end,3);
    %cal the # of frames in the video sequence
    i = i+1;
    j = j+1;
end
fprintf("Total Frames in the video sequence:%d\n",i);
% Defining the Frame 2 i.e the first frame from given GoP(6:9)[IPPPP] as
% intra-frame
rf = y(:,:,2);
figure(1)
imshow(rf)
title('I-Frame')
% computing total MB possible for the given video sequence.
t_mb = (ceil(size(rf,1)/16))*(ceil(size(rf,2)/16));
fprintf("Total MB possible:%d\n",t_mb);
% Var to compute the total comparisons done using the below algorithm.
comp = 0;
% iterating through the loop to find difference matrix,motion estimation
% and motion vector
for i = 6:9
    % Extracting the Y,cb and Cr compoments and downsampling the chromiance
    % of the video frame image.
    y(:,:,i-1)  = ycbcr(:,:,1);
    cb(:,:,i-1) = ycbcr(1:2:end,1:2:end,2);
    cr(:,:,i-1) = ycbcr(1:2:end,1:2:end,3);
    % setting the current and reference frames for motion prediction
    tgt_frm = y(:,:,i);
    ref_frm = y(:,:,i+1);
    tgt_frm_2 = double(tgt_frm);
    ref_frm_2 = double(ref_frm);
    % defining the MB size as 16 for Y comp.
    mb_size = 16;
    % getting total rows and column in the current frame
    [row,col] = size(tgt_frm_2);
    temp_diff_frm = zeros(mb_size,mb_size);
    disp_vect = zeros(1,2);
    % two matrices for holding the diff frame and tgt frame
    search_window = zeros(t_mb,2,2);
    % var to compute the search window movement.
    c = 1;
    for r_mb = 1:mb_size:row
        for c_mb = 1:mb_size:col
            % Extracting the temporary target frame window.
            temp_tf_mb = tgt_frm_2([r_mb:r_mb+mb_size-1],[c_mb:c_mb+mb_size-1]);
            max_val = 66000;
            for blk_r = -8:8
                for blk_c = -8:8
                    % Now padding the extra rows and columns inside the
                    % search window
                    inc_row = r_mb+blk_r;
                    inc_col = c_mb+blk_c;
                    if ((inc_row + 16 - 1) <= row) && ((inc_col +16 - 1) <= col) && (inc_row > 0)  && (inc_col > 0)
                        rf_mb_sw = ref_frm_2(inc_row:inc_row+mb_size-1,inc_col:inc_col+mb_size-1);
                        temp_diff_frm = temp_tf_mb - rf_mb_sw;
                        % computing the MSE for current MB and reference MB
                        % within the computed search window
                        mse_mb = sum(sum(temp_diff_frm.^2));
                        mse_mb = mse_mb./256;
                        % Finding the closest block matching also computing
                        % the MAD
                        if mse_mb < max_val
                            max_val = mse_mb;
                            disp_vect = [inc_row - r_mb,inc_col - c_mb];
                            rc_img(r_mb:r_mb+mb_size -1,c_mb:c_mb+mb_size -1) = ref_frm_2(inc_row:inc_row+mb_size -1,inc_col:inc_col+mb_size -1);
                            % incrementing the comparison count to display
                            % total MAD comaprisons at the end of the loop
                            comp = comp +1;
                        elseif mse_mb == max_val
                            pad_r_c = (r_mb - inc_row)^2 + (c_mb - inc_col)^2;
                            if pad_r_c < max_val
                                disp_vect = [inc_row - r_mb,inc_col - c_mb];
                            end
                        end
                    end
                end
            end
            diff_frm(r_mb:r_mb+mb_size -1,c_mb:c_mb+mb_size -1) = temp_diff_frm;
            % Now updating the search window
            search_window(c,:,1) = [r_mb,c_mb];
            search_window(c,:,2) = disp_vect;
            c = c+1;
        end
    end
    fprintf("\nThe MSE of Frame:%d and Frame:%d\n",(i),(i+1));
    disp(mse_mb);
    figure()
    % displaying the Motion Vector Representation using the quiver command
    quiver(search_window(:,2,1), search_window(:,1,1), search_window(:,2,2), search_window(:,1,2));
    title(['Motion vector Representation of Y comp. image frame:',num2str(i),'and image frame:',num2str(i+1)]);
    grid on
    reconst_img = uint8(rc_img);
    figure()
    subplot(2,2,1),imshow(tgt_frm),title(['Y comp. Original Video Frame:',num2str(i)])
    subplot(2,2,2),imshow(reconst_img),title(['Predicted Target Y comp. of Video Frame:',num2str(i+1)])
    pred_err = tgt_frm - reconst_img;
    subplot(2,2,3),imshow(pred_err),title('Error between predicted and target frame')
end
[add,sub] = exhaustive_search_load_cal(16);
fprintf("Total additions for while computing:%d\nTotal substractions for while computing:%d\nTotal comparisons for while computing:%d\n",add,sub,comp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function: exhaustive_search_load_cal()
% imput: (int) macro block size
% Return: (int_array) returns total additions and substractions performed
% during computation of motion estimation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [t_add,t_sub] = exhaustive_search_load_cal(mb_size)
    t_s = ((2*8)+1)^2;
    t_add = (2*(mb_size^2))*t_s;
    t_sub = (mb_size^2)*t_s;
end