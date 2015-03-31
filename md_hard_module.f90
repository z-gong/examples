MODULE md_hard_module

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: n, r, v, coltime, partner
  PUBLIC :: update, overlap, collide

  INTEGER                              :: n       ! number of atoms
  REAL,    DIMENSION(:,:), ALLOCATABLE :: r, v    ! positions, velocities (3,n)
  REAL,    DIMENSION(:),   ALLOCATABLE :: coltime ! time to next collision (n)
  INTEGER, DIMENSION(:),   ALLOCATABLE :: partner ! collision partner (n)

CONTAINS

  SUBROUTINE update ( i, j1, j2, sigma_sq ) ! updates collision details for atom i
    INTEGER, INTENT(in) :: i, j1, j2
    REAL,    INTENT(in) :: sigma_sq

    INTEGER            :: j
    REAL, DIMENSION(3) :: rij, vij
    REAL               :: rijsq, vijsq, bij, tij, discr

    coltime(i) = HUGE(1.0)

    DO j = j1, j2

       rij(:) = r(:,i) - r(:,j)
       rij(:) = rij(:) - ANINT ( rij(:) )
       vij(:) = v(:,i) - v(:,j)
       bij  = dot_PRODUCT ( rij, vij )

       IF ( bij < 0.0 ) THEN

          rijsq = SUM ( rij**2 )
          vijsq = SUM ( vij**2 )
          discr = bij ** 2 - vijsq * ( rijsq - sigma_sq )

          IF ( discr > 0.0 ) THEN

             tij = ( -bij - SQRT ( discr ) ) / vijsq

             IF ( tij < coltime(i) ) THEN

                coltime(i) = tij
                partner(i) = j

             END IF

          END IF

       END IF

    END DO

  END SUBROUTINE update

  FUNCTION overlap ( sigma_sq ) ! tests configuration for pair overlaps
    LOGICAL          :: overlap  ! function result
    REAL, INTENT(in) :: sigma_sq ! particle diameter squared

    INTEGER            :: i, j
    REAL, DIMENSION(3) :: rij
    REAL               :: rij_sq, rij_mag
    REAL,    PARAMETER :: tol = 1.0e-4 

    overlap  = .FALSE.

    DO i = 1, n - 1
       DO j = i + 1, n

          rij(:) = r(:,i) - r(:,j)
          rij(:) = rij(:) - ANINT ( rij(:) )
          rij_sq = SUM ( rij**2 )

          IF ( rij_sq < sigma_sq ) THEN
             rij_mag = SQRT ( rij_sq / sigma_sq )
             WRITE(*,'(''i,j,rij/sigma = '',2i5,f15.8)') i, j, rij_mag ! Warning
             IF ( ( 1.0 - rij_mag ) > tol ) overlap = .TRUE.
          END IF

       END DO
    END DO

  END FUNCTION overlap

  SUBROUTINE collide ( i, j, sigma_sq, virial ) ! collision dynamics
    INTEGER, INTENT(in) :: i, j
    REAL, INTENT(in)                  :: sigma_sq
    REAL,               INTENT(out)   :: virial

    ! it is assumed that i and j are in contact
    ! the routine also computes the collisional virial

    REAL, DIMENSION(3) :: rij, vij
    REAL :: factor

    rij(:) = r(:,i) - r(:,j)
    rij(:) = rij(:) - ANINT ( rij(:) )
    vij(:) = v(:,i) - v(:,j)

    factor = dot_PRODUCT ( rij, vij ) / sigma_sq
    vij = - factor * rij

    v(:,i) = v(:,i) + vij
    v(:,j) = v(:,j) - vij
    virial = dot_PRODUCT ( vij, rij )
  END SUBROUTINE collide

END MODULE md_hard_module
