close all; clear all; clc
% coco path
dataset_base = "D:\coco2017\train2017";
annotationFile = "D:\coco2017\annotations_trainval2017\annotations\instances_train2017.json";

txt = fileread('D:\coco2017\annotations_trainval2017\annotations\instances_train2017.json');

%% criando tabela do dataset com arquivo .json
val_json  = jsondecode(txt);%transforma json para ttxt

%dataset_base=0;
%header = ["imageFilename";"bbox"];
info = struct2table(val_json.annotations); %criando as tabelas
categories=struct2table(val_json.categories); %criando as tabelas
img_files=struct2table(val_json.images); %criando as tabelas
img_files = sortrows(img_files, 8);
[total_img, ~] = size(img_files);
B = sortrows(info,[4 6]);
[len, ~] = size(info);



C = cell(117266,81); % hard code, unknow total images annotations


%%
img_actual = B.image_id(1);
temp = B.bbox(1);
temp = temp{1};
bbox_actual = temp';
img_actual = B.image_id(1);
cat = B.category_id(1);
image_index=1;
flag=false;
invalid_bboxes=[]
for index=1:len
         height = img_files.height(find(img_files.id==B.image_id(index)));
         width = img_files.width(find(img_files.id==B.image_id(index)));   
    if (img_actual==B.image_id(index))
        cat = B.category_id(index);
        cat = find(categories.id==cat);
        [new_bbox,valid] = validateBbox(B.bbox(index), height, width);
        if (valid)
            C{image_index,cat+1}=[C{image_index,cat+1}; new_bbox];
            C{image_index,1}=strcat(dataset_base, '\', num2str(img_actual,'%012.f'), '.jpg');
        else
            invalid_bboxes=[invalid_bboxes image_index];
        end
        
    else
        image_index = image_index+1;
        cat = B.category_id(index);
        cat = find(categories.id==cat);
        [new_bbox,valid] = validateBbox(B.bbox(index), height, width);
        img_actual = B.image_id(index);
        if (valid)
            C{image_index,cat+1}=[C{image_index,cat+1}; bbox_actual];
            C{image_index,1}=strcat(dataset_base, '\', num2str(img_actual,'%012.f'), '.jpg');
        else
            invalid_bboxes=[invalid_bboxes image_index];
        end
        
    end

end



categories = struct2table(val_json.categories);

%find(categories.id==61)
%segments_info = val_json.annotations.segments_info;

%filename=[]

%filename = string(info.file_name);

%image_id = string(info.image_id);

%teste = [filename image_id];
%[seg_r seg_c] = size(info);
%[cat_r cat_c]=size(categories);


%table_teste= table('Size', [size(segments_info) size(categories)+1],...
%    'VariableNames', {'imageFilename', {categories}});

% C = cell(seg_r,cat_r);
% for index=1:size(info)
%     filename = info(index, "file_name");
%     segments_info = info.segments_info(index);
%     segments_info = segments_info{1};
%     anotations = struct2table(segments_info, 'AsArray',true);
%     [seg_info_size ~] = size(anotations);
%     C{index,1} = filename.file_name{1};
%     for index2=1:seg_info_size
%         bbox =  anotations.bbox(index2);
%         category_id =  anotations.category_id(index2);            
%         C{index,category_id+1} = bbox{:};
%     end
% end

T = cell2table(C);
categories_name=categories.name;
categories_temp= cellstr(categories_name);

%find(categories_name='person')

T.Properties.VariableNames([1:81]) = {'imageFilename', categories_temp{:}};

%% img 049 bbox passando uns 2 a 3 pixels da img
%%formatar a imagem pra inteiro e somar mais 1 antes de fazer os calculos
%%if e else

data=T(1:117254,:); %retirando imagens com bbox <=1
%data=T;

%save cocoDatasetGroundTruth data


