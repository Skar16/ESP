% roots_demo.m
%
% US 07-Nov-23
%
% demo for finding M_opt
clear
close all
Fs = 50e3;
fpass = 2700;
fstop = 2900;

a = fstop^2 - fpass^2;
b = -(fpass + fstop)^2;
c = 2 * Fs  * (fpass   + fstop);
d = -Fs^2;

my_polynom = [a b c d]
roots(my_polynom)

