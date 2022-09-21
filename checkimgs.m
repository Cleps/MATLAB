clear all;



dataset_base = "D:\coco2017\train2017";
imds = imageDatastore(dataset_base);
%%
for i =1:length(imds.Files)
    img = readimage(imds,i);
    [~, ~, c] = size(img);
    if c~=3
        disp(imds.Files{i});    
        img = cat(3,img,img,img);
        imwrite(img, imds.Files{i});
    end
end