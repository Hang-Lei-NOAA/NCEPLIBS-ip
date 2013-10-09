 SUBROUTINE GDSWIZ04(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,  &
                     LROT,CROT,SROT)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  GDSWIZ04   GDS WIZARD FOR GAUSSIAN CYLINDRICAL
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM DECODES THE GRIB GRID DESCRIPTION SECTION
!           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63)
!           AND RETURNS ONE OF THE FOLLOWING:
!             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
!             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
!           FOR GAUSSIAN CYLINDRICAL PROJECTIONS.
!           IF THE SELECTED COORDINATES ARE MORE THAN ONE GRIDPOINT
!           BEYOND THE THE EDGES OF THE GRID DOMAIN, THEN THE RELEVANT
!           OUTPUT ELEMENTS ARE SET TO FILL VALUES.
!           THE ACTUAL NUMBER OF VALID POINTS COMPUTED IS RETURNED TOO.
!
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
! 1999-04-08  IREDELL  USE SUBROUTINE SPLAT
!
! USAGE:    CALL GDSWIZ04(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,
!    &                    LROT,CROT,SROT)
!
!   INPUT ARGUMENT LIST:
!     KGDS     - INTEGER (200) GDS PARAMETERS AS DECODED BY W3FI63
!     IOPT     - INTEGER OPTION FLAG
!                (+1 TO COMPUTE EARTH COORDS OF SELECTED GRID COORDS)
!                (-1 TO COMPUTE GRID COORDS OF SELECTED EARTH COORDS)
!     NPTS     - INTEGER MAXIMUM NUMBER OF COORDINATES
!     FILL     - REAL FILL VALUE TO SET INVALID OUTPUT DATA
!                (MUST BE IMPOSSIBLE VALUE; SUGGESTED VALUE: -9999.)
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT>0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT>0
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT<0
!                (ACCEPTABLE RANGE: -360. TO 360.)
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT<0
!                (ACCEPTABLE RANGE: -90. TO 90.)
!     LROT     - INTEGER FLAG TO RETURN VECTOR ROTATIONS IF 1
!
!   OUTPUT ARGUMENT LIST:
!     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT<0
!     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT<0
!     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT>0
!     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT>0
!     NRET     - INTEGER NUMBER OF VALID POINTS COMPUTED
!     CROT     - REAL (NPTS) CLOCKWISE VECTOR ROTATION COSINES IF LROT=1
!     SROT     - REAL (NPTS) CLOCKWISE VECTOR ROTATION SINES IF LROT=1
!                (UGRID=CROT*UEARTH-SROT*VEARTH;
!                 VGRID=SROT*UEARTH+CROT*VEARTH)
!
! SUBPROGRAMS CALLED:
!   SPLAT      COMPUTE LATITUDE FUNCTIONS
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,        INTENT(IN   ) :: KGDS(200)
 INTEGER,        INTENT(IN   ) :: IOPT, LROT, NPTS
 INTEGER,        INTENT(  OUT) :: NRET
!
 REAL,           INTENT(IN   ) :: FILL
 REAL,           INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
 REAL,           INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
 REAL,           INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
!
 REAL,           PARAMETER     :: PI=3.14159265358979
 REAL,           PARAMETER     :: DPR=180./PI
!
 INTEGER                       :: IM, JM, ISCAN, JSCAN
 INTEGER                       :: J, J1, JA, JG, JH, N
!
 REAL,           ALLOCATABLE   :: ALAT(:),ALAT_TEMP(:),BLAT(:)
 REAL                          :: DLON, HI, RLATA, RLATB
 REAL                          :: RLAT1, RLON1, RLON2, WB
 REAL                          :: XMIN, XMAX, YMIN, YMAX
 REAL                          :: YPTSA, YPTSB
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IF(KGDS(1).EQ.004) THEN
   IM=KGDS(2)
   JM=KGDS(3)
   RLAT1=KGDS(4)*1.E-3
   RLON1=KGDS(5)*1.E-3
   RLON2=KGDS(8)*1.E-3
   JG=KGDS(10)*2
   ISCAN=MOD(KGDS(11)/128,2)
   JSCAN=MOD(KGDS(11)/64,2)
   HI=(-1.)**ISCAN
   JH=(-1)**JSCAN
   DLON=HI*(MOD(HI*(RLON2-RLON1)-1+3600,360.)+1)/(IM-1)
   ALLOCATE(ALAT(0:JG+1))
   ALLOCATE(ALAT_TEMP(JG))
   ALLOCATE(BLAT(JG))
   CALL SPLAT(4,JG,ALAT_TEMP,BLAT)
   DO JA=1,JG
     ALAT(JA)=DPR*ASIN(ALAT_TEMP(JA))
   ENDDO
   DEALLOCATE(ALAT_TEMP,BLAT)
   ALAT(0)=180.-ALAT(1)
   ALAT(JG+1)=-ALAT(0)
   J1=1
   DO WHILE(J1.LT.JG.AND.RLAT1.LT.(ALAT(J1)+ALAT(J1+1))/2)
     J1=J1+1
   ENDDO
   XMIN=0
   XMAX=IM+1
   IF(IM.EQ.NINT(360/ABS(DLON))) XMAX=IM+2
   YMIN=0.5
   YMAX=JM+0.5
   NRET=0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE GRID COORDINATES TO EARTH COORDINATES
   IF(IOPT.EQ.0.OR.IOPT.EQ.1) THEN
     DO N=1,NPTS
       IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND. &
          YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
         RLON(N)=MOD(RLON1+DLON*(XPTS(N)-1)+3600,360.)
         J=MIN(INT(YPTS(N)),JM)
         RLATA=ALAT(J1+JH*(J-1))
         RLATB=ALAT(J1+JH*J)
         WB=YPTS(N)-J
         RLAT(N)=RLATA+WB*(RLATB-RLATA)
         NRET=NRET+1
         IF(LROT.EQ.1) THEN
           CROT(N)=1
           SROT(N)=0
         ENDIF
       ELSE
         RLON(N)=FILL
         RLAT(N)=FILL
       ENDIF
     ENDDO
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSLATE EARTH COORDINATES TO GRID COORDINATES
   ELSEIF(IOPT.EQ.-1) THEN
     DO N=1,NPTS
       XPTS(N)=FILL
       YPTS(N)=FILL
       IF(ABS(RLON(N)).LE.360.AND.ABS(RLAT(N)).LE.90) THEN
         XPTS(N)=1+HI*MOD(HI*(RLON(N)-RLON1)+3600,360.)/DLON
         JA=MIN(INT((JG+1)/180.*(90-RLAT(N))),JG)
         IF(RLAT(N).GT.ALAT(JA)) JA=MAX(JA-2,0)
         IF(RLAT(N).LT.ALAT(JA+1)) JA=MIN(JA+2,JG)
         IF(RLAT(N).GT.ALAT(JA)) JA=JA-1
         IF(RLAT(N).LT.ALAT(JA+1)) JA=JA+1
         YPTSA=1+JH*(JA-J1)
         YPTSB=1+JH*(JA+1-J1)
         WB=(ALAT(JA)-RLAT(N))/(ALAT(JA)-ALAT(JA+1))
         YPTS(N)=YPTSA+WB*(YPTSB-YPTSA)
         IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND. &
            YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
           NRET=NRET+1
           IF(LROT.EQ.1) THEN
             CROT(N)=1
             SROT(N)=0
           ENDIF
         ELSE
           XPTS(N)=FILL
           YPTS(N)=FILL
         ENDIF
       ENDIF
     ENDDO
   ENDIF
   DEALLOCATE(ALAT)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  PROJECTION UNRECOGNIZED
 ELSE
   IF(IOPT.GE.0) THEN
     DO N=1,NPTS
       RLON(N)=FILL
       RLAT(N)=FILL
     ENDDO
   ENDIF
   IF(IOPT.LE.0) THEN
     DO N=1,NPTS
       XPTS(N)=FILL
       YPTS(N)=FILL
     ENDDO
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE GDSWIZ04
