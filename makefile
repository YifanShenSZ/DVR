########################################
#                                      #
#        Makefile for OneDimDVR        #
#                                      #
########################################

compiler = ifort
MyLibDir = /home-4/yshen57@jhu.edu/Library/Fortran-Library
MyLib = $(MyLibDir)/General.f90 $(MyLibDir)/Mathematics.f90 $(MyLibDir)/LinearAlgebra.f90
src = Basic.f90 DVR.f90 Main.f90
exe = OneDimDVR.exe
# -static causes strange bug in ifort 2018
flag = -mkl -O3 -ipo -no-prec-div -fp-model fast=2 -march=core-avx2 -mtune=core-avx2

$(exe): $(MyLib) $(src)
	$(compiler) $(flag) $^ -o $(exe)

clean:
	rm *.mod