close all; clear all; clc
% coco path
dataset_base = "D:\coco2017\train2017";
annotationFile = "D:\coco2017\annotations_trainval2017\annotations\instances_train2017.json";


[allCOCOdata,cocoDatastore,coconames] = cocoAPI(dataset_base,annotationFile);% take very few minites
%%

C = cell(100,3); % hard code, unknow total images annotations

for index=1:100
    img_actual = allCOCOdata.image_id(index);
    height = allCOCOdata.height(index);
    width = allCOCOdata.width(index)
    bbox = allCOCOdata.bbox(index);
    bbox = bbox{1};
    [sz, ~]= size(bbox);
    for index1=1:sz
        if bbox(index1,1)+bbox(index1,4)>height
            bbox(index1,4)= height-bbox(index1,1);
        end
        if bbox(index1,2)+bbox(index1,3)>width
            bbox(index1,2)= height-bbox(index1,2);
        end
    end
    bbox_actual = int64(bbox)+1;
    category = allCOCOdata.category_id(index);
    C{index,1}=strcat(dataset_base, '\', num2str(img_actual,'%012.f'), '.jpg');
    C{index,3}=category{1};
    C{index,2}=bbox_actual;
    %image_id(index)
    T = cell2table(C);


    T.Properties.VariableNames = {'imageFilename', 'Boxes', 'Labels'};
    data=T;
    save cocoDatasetGroundTruth data
end

