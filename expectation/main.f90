!Calculate expectations from OneDimDVR Wigner distribution
program main
    use polynomial
    implicit none
    !polynomials to calculate expectations
    integer::NPolynomials
    type(PolDef), allocatable, dimension(:)::PolDefs
    real*8, allocatable, dimension(:,:,:)::expectations
    !space and momenta grid points and Wigner distribution from Wigner routine
    integer::NStates, NSnapshots, NGrids, NMomenta
    real*8, allocatable, dimension(:)::grids, momenta
    real*8, allocatable, dimension(:,:)::Wigner
    !work variable
    character*128::line
    character*128, allocatable, dimension(:)::strs
    integer::order, i, j, k

    write(*,*)"Calculate expectations from OneDimDVR Wigner distribution"
    write(*,*)"Yifan Shen 2020"
    write(*,*)
    !Read input
    NPolynomials = 0
    open(unit=99, file="expectation.in", status="old")
        !Count how many terms there are
        do
            read(99, *, iostat=i)
            if (i /= 0) exit
            NPolynomials = NPolynomials + 1
        end do
        rewind 99
        !Allocate work space: assuming the 1st term has highest order
        read(99, *)order
        allocate(strs(order))
        rewind 99
        !Read the definition of terms
        allocate(PolDefs(NPolynomials))
        do i = 1, NPolynomials
            read(99, "(I5)", advance="no")order
            read(99, "(A)")line
            call parse(line, ' ', strs, j)
            call PolDefs(i)%construct(order, strs)
        end do
    close(99)
    !Read space and momentum grid points from from Wigner routine
    open(unit=99, file="checkpoint.out")
        read(99,*); read(99,*)NStates    
        read(99,*); read(99,*)NSnapshots
        read(99,*); read(99,*)NGrids
        read(99,*); read(99,*)NMomenta
    close(99)
    allocate(grids(NGrids))
    open(unit=99, file="grids.out", form="unformatted")
        read(99)grids
    close(99)
    allocate(momenta(NMomenta))
    open(unit=99, file="momenta.out", form="unformatted")
        read(99)momenta
    close(99)
    allocate(Wigner(NGrids, NMomenta))

    !Calculate expectations
    write(*,*)"Calculating expectations..."
    allocate(expectations(NPolynomials, NStates, NSnapshots))
    do j = 1, NStates
        write(line,*)j
        open(unit=99+j, file="Wigner"//trim(adjustl(line))//".out", form="unformatted")
    end do
    do i = 1, NSnapshots
        do j = 1, NStates
            read(99+j)Wigner
            call Wigner2expectation(grids, momenta, Wigner, PolDefs, expectations(:,j,i), NGrids, NMomenta, NPolynomials)
        end do
    end do
    do j = 1, NStates
        close(99+j)
    end do

    !Output
    open(unit=99, file="expectation.out", form="unformatted", status="replace")
        write(99)expectations(:,:,:)
    close(99)

contains
subroutine Wigner2expectation(grids, momenta, Wigner, PolDefs, expectations, NGrids, NMomenta, NPolynomials)
    integer, intent(in)::NGrids, NMomenta, NPolynomials
    real*8, dimension(NGrids), intent(in)::grids
    real*8, dimension(NMomenta), intent(in)::momenta
    real*8, dimension(NGrids, NMomenta), intent(in)::Wigner
    type(PolDef), dimension(NPolynomials), intent(in)::PolDefs
    real*8, dimension(NPolynomials), intent(out)::expectations
    integer::i, j, k
    real*8::dq, dp
    dq = grids(2) - grids(1)
    dp = momenta(2) - momenta(1)
    expectations = 0d0
    !$OMP PARALLEL DO PRIVATE(i, j, k)
    do i = 1, NPolynomials
        do j = 1, NMomenta
            do k = 1, NGrids
                expectations(i) = expectations(i) + Wigner(j, k) &
                                * PolDefs(i)%evaluate(grids(j), momenta(k))
            end do
        end do
    end do
    !$OMP END PARALLEL DO
    expectations = expectations * dq * dp
end subroutine Wigner2expectation

end program main