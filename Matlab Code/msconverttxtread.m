function out = msconverttxtread(filepath)

mz_struct = importdata(filepath,'\t');
out = [];
temp1 = [];
temp2 = [];
precursorflag = 0;

j = 0; k = 0;
for i = 1:1:size(mz_struct,1)
    line = mz_struct{i};
    
    scanidx = regexp(line,'scan=');
    mzidx = regexp(line,'isolation window target m/z');
    
    if ~isempty(scanidx) && ~precursorflag
        temp1 = str2num(line(scanidx+5:end));
        precursorflag = 1;
        scanidx = [];
    end
    
    if ~isempty(mzidx) && precursorflag
        temp2 = str2num(line(mzidx+29:end-5));
        out = [out;[temp1 temp2]];
        precursorflag = 0;
        mzidx = []; temp1 = []; temp2 = [];
        j = j+1;
    end
end
end