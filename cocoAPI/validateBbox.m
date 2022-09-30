function [new_bbox,valid] = validateBbox(bbox, height, width)
    %====================================================================
    %This function receive bbox cell, {[x, y, width, height]} and width,
    %height from image respective
    %====================================================================
    %Scalar
    scalar_w = 227/width; scalar_h = 227/height;

    % add +1 to size of bbox (not start in 0)
    temp = bbox{1}+1;
    valid = length(temp)==4;
    %check if size of bbox h,w is less than image
    if temp(2,1)+temp(4,1)>height
        temp(4,1)= height-temp(2,1);
    end
    if temp(1,1)+temp(3,1)>width
        temp(3,1)= width-temp(1,1);
    end
    
    new_bbox = int64(temp'); % transpose column to row
    %reescale
    new_bbox = [new_bbox(1,1)*scalar_w new_bbox(1,2)*scalar_h new_bbox(1,3)*scalar_w new_bbox(1,4)*scalar_h];
    %check size of w, h
    if (new_bbox(1,4)<=1) || (new_bbox(1,3)<=1)
        %disp(bbox_actual)
        valid=false;
        new_bbox=[];
    end
end

