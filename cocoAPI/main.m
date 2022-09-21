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
for index=1:len
       %read current image
       %insert data in table
       % if current image is equal to actual insert in actual line else
       % insert in next line
            
         height = img_files.height(find(img_files.id==B.image_id(index)));
         width = img_files.width(find(img_files.id==B.image_id(index)));
        
    if (img_actual==B.image_id(index)) %10
        cat = B.category_id(index);
        cat = find(categories.id==cat);
        temp = B.bbox(index);
        temp = temp{1}+1; %COLOCANDO +1 AQUI
        if temp(2,1)+temp(4,1)>height
           temp(4,1)= height-temp(2,1);
        end
        if temp(1,1)+temp(3,1)>width
           temp(3,1)= width-temp(1,1);
        end

        bbox_actual = int64(temp'); %TIRANDO +1 DAQ
        C{image_index,cat+1}=[C{image_index,cat+1}; bbox_actual];
        C{image_index,1}=strcat(dataset_base, '\', num2str(img_actual,'%012.f'), '.jpg'); %9, 1
        
    else 
        image_index = image_index+1;
        cat = B.category_id(index);
        cat = find(categories.id==cat);
        temp = B.bbox(index);
        temp = temp{1}+1;  %ADICIONADO +1 AQ
        
        if temp(2,1)+temp(4,1)>height
           temp(4,1)= height-temp(2,1);
        end
        if temp(1,1)+temp(3,1)>width
           temp(3,1)= width-temp(1,1);
        end
        % MOVENDO BBOX ATUAL + 1 DAQ ---------------------------------------
        bbox_actual = int64(temp');
        img_actual = B.image_id(index);

        C{image_index,cat+1}=[C{image_index,cat+1}; bbox_actual];
        C{image_index,1}=strcat(dataset_base, '\', num2str(img_actual,'%012.f'), '.jpg');
        
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


data=T;

save cocoDatasetGroundTruth data


