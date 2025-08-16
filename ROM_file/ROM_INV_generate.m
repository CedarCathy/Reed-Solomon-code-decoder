clc
x = 1:255;
%%Reed-Solomon code parameters
n = 255;
k = 239;
t = 8;
poly=rsgenpoly(255,239,[],0);
g_poly = gf(poly,8,'D8+D4+D3+D2+1');
%primitive polynomial
prim_poly = primpoly(t);
x = gf(x,t,prim_poly);
unit = gf(1,t,prim_poly);
x_inv = unit./x;
fid = fopen("ROM_INV.coe","wt");
fprintf(fid,'MEMORY_INITIALIZATION_RADIX = 10;\n');
fprintf(fid,'MEMERY_INITIALIZATION_VECTOR = \n');
fprintf(fid,'%d,\n',0);
for i = 1 : 255
    fprintf(fid,'%d,\n',x_inv.x(i));
end
fclose(fid);