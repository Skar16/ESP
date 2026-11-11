% roots_demo.m
%
% US 07-Nov-23
%
% demo for finding M_opt
clear
close all
Fs = 8000;
fpass = 1000;
fstop = 1100;

a = fstop^2 - fpass^2;
b = -(fpass + fstop)^2;
c = 2 * Fs  * (fpass   + fstop);
d = -Fs^2;

my_polynom = [a b c d]
roots(my_polynom)

