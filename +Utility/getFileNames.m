       %% File finding
       function [ListOfFiles, nbFiles] = getFileNames(LoadDirectory, extension)
           % This function returns the names of .mat files in a given directory.
           % Input: directory location as string e.g. '/home/andries/DataForProjects/SleepData/Patient1/'
           % Output: cell with string entries e.g.  {'pat_1_night_1_interval_1.mat'}...                                             .
           
           if 7~=exist(LoadDirectory,'dir')
               error('This directory does not exist.')
           end
%            addpath(genpath(LoadDirectory))
           ListOfFiles = dir([LoadDirectory, extension]);
           ListOfFiles = {ListOfFiles.name}';
           parentDir = strcmp(ListOfFiles,{'.'});
           parentparentDir =  strcmp(ListOfFiles,{'..'});
           ListOfFiles(parentDir | parentparentDir) = [];
           nbFiles = length(ListOfFiles); 
       end