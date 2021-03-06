 SUBROUTINE IPXWAFS2(IDIR,M1,M2,KM,KGDS1,IB1,L1,F1,KGDS2,IB2,L2,F2,IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  IPXWAFS2   EXPAND OR CONTRACT WAFS GRIDS
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM TRANSFORMS BETWEEN THE THINNED WAFS GRIDS
!           AS USED FOR TRANSMITTING TO THE AVIATION COMMUNITY
!           AND THEIR FULL EXPANSION AS USED FOR GENERAL INTERPOLATION
!           AND GRAPHICS.  THE WAFS GRIDS ARE LATITUDE-LONGITUDE GRIDS
!           THINNED ONLY IN THE ZONAL DIRECTION AS INDICATED
!           BY THE PL PARAMETERS IN THE GRIB GRID DESCRIPTION SECTION.
!           THE PL PARAMETERS MUST BE SUPPLIED FOR CONTRACTION
!           (STARTING AT KGDS1(22)).  OTHERWISE (IF KGDS1(22)<=0)
!           GRID CONTRACTION IS PERFORMED SPECIFICALLY FOR
!           THE 1.25 DEGREE NCEP WAFS GRID IDENTIFICATIONS 37-44.
!           THE EXPANSION AND CONTRACTION OF THE FIELDS ARE DONE
!           BY LINEAR INTERPOLATION, SO THAT THEY ARE NOT REVERSIBLE.
!           THIS VERSION ALLOWS A BITMAP.
!
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
!   99-01-25  Gilbert   - changed bitmap fields from LOGICAL to LOGICAL*1
!
! USAGE:    CALL IPXWAFS2(IDIR,M1,M2,KM,
!    &                    KGDS1,IB1,L1,F1,KGDS2,IB2,L2,F2,IRET)
!
!   INPUT ARGUMENT LIST:
!     IDIR     - INTEGER TRANSFORM OPTION
!                (+1 TO EXPAND THINNED FIELDS TO FULL FIELDS)
!                (-1 TO CONTRACT FULL FIELDS TO THINNED FIELDS)
!     M1       - INTEGER SKIP NUMBER BETWEEN THINNED GRID FIELDS
!     M2       - INTEGER SKIP NUMBER BETWEEN FULL GRID FIELDS
!     KM       - INTEGER NUMBER OF FIELDS TO TRANSFORM
!     KGDS1    - INTEGER (200) GDS PARMS OF THINNED GRID IF IDIR>0
!                (IF IDIR<0, THEN EITHER THE PL PARAMETERS STARTING AT
!                 KGDS1(22) MUST BE SUPPLIED OR IF KGDS1(22)<=0,
!                 THEN THE PL PARAMETERS DEFAULT TO THOSE FOR
!                 SPECIFIC NCEP WAFS GRIDS 37-44).
!     IB1      - INTEGER (KM) THINNED BITMAP FLAGS IF IDIR>0
!     L1       - LOGICAL*1 (M1,KM) THINNED BITMAP FIELDS IF IDIR>0
!     F1       - REAL (M1,KM) THINNED GRID FIELDS IF IDIR>0
!     KGDS2    - INTEGER (200) GDS PARMS OF FULL GRID IF IDIR<0
!     IB2      - INTEGER (KM) FULL BITMAP FLAGS IF IDIR<0
!     L2       - LOGICAL*1 (M1,KM) FULL BITMAP FIELDS IF IDIR<0
!     F2       - REAL (M2,KM) FULL GRID FIELDS IF IDIR<0
!
!   OUTPUT ARGUMENT LIST:
!     KGDS1    - INTEGER (200) GDS PARMS OF THINNED GRID IF IDIR<0
!     IB1      - INTEGER (KM) THINNED BITMAP FLAGS IF IDIR<0
!     L1       - LOGICAL*1 (M1,KM) THINNED BITMAP FIELDS IF IDIR<0
!     F1       - REAL (M1,KM) THINNED GRID FIELDS IF IDIR<0
!     KGDS2    - INTEGER (200) GDS PARMS OF FULL GRID IF IDIR>0
!     IB2      - INTEGER (KM) FULL BITMAP FLAGS IF IDIR>0
!     L2       - LOGICAL*1 (M1,KM) FULL BITMAP FIELDS IF IDIR>0
!     F2       - REAL (M2,KM) FULL GRID FIELDS IF IDIR>0
!     IRET     - INTEGER RETURN CODE
!                0    SUCCESSFUL TRANSFORMATION
!                1    IMPROPER GRID SPECIFICATION
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,              INTENT(IN   ) :: IDIR, KM, M1, M2
 INTEGER,              INTENT(INOUT) :: IB1(KM), IB2(KM)
 INTEGER,              INTENT(INOUT) :: KGDS1(200),KGDS2(200)
 INTEGER,              INTENT(  OUT) :: IRET
!
 LOGICAL*1,            INTENT(INOUT) :: L1(M1,KM),L2(M2,KM)
!
 REAL,                 INTENT(INOUT) :: F1(M1,KM),F2(M2,KM)
!
 INTEGER                             :: I, IM, ISCAN, J
 INTEGER                             :: IA, IB
 INTEGER                             :: IM1, IM2, IS1, IS2
 INTEGER                             :: K, NPWAFS(73)
!
 REAL                                :: DLON, HI, RAT1, RAT2
 REAL                                :: RLON1, RLON2, WA, WB, X1, X2
!
 DATA NPWAFS/ &
      73, 73, 73, 73, 73, 73, 73, 73, 72, 72, 72, 71, 71, 71, 70, &
      70, 69, 69, 68, 67, 67, 66, 65, 65, 64, 63, 62, 61, 60, 60, & 
      59, 58, 57, 56, 55, 54, 52, 51, 50, 49, 48, 47, 45, 44, 43, &
      42, 40, 39, 38, 36, 35, 33, 32, 30, 29, 28, 26, 25, 23, 22, &
      20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2/
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSFORM GDS
 IRET=0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  EXPAND THINNED GDS TO FULL GDS
 IF(IDIR.GT.0) THEN
   IF(MOD(KGDS1(11)/32,2).EQ.0.AND.KGDS1(20).EQ.33) THEN
     KGDS2(1:18)=KGDS1(1:18)
     IM=0
     DO J=22,21+KGDS1(3)
       IM=MAX(IM,KGDS1(J))
     ENDDO
     KGDS2(2)=IM
     RLON1=KGDS2(5)*1.E-3
     RLON2=KGDS2(8)*1.E-3
     ISCAN=MOD(KGDS2(11)/128,2)
     HI=(-1.)**ISCAN
     DLON=HI*(MOD(HI*(RLON2-RLON1)-1+3600,360.)+1)/(IM-1)
     KGDS2(9)=NINT(DLON*1.E3)
     KGDS2(19)=0
     KGDS2(20)=255
     KGDS2(21)=0
     KGDS2(22)=0
   ELSE
     IRET=1
   ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  CONTRACT FULL GDS TO THINNED GDS
 ELSEIF(IDIR.LT.0) THEN
!  PL PARAMETERS PROVIDED
   IF(MOD(KGDS2(11)/32,2).EQ.0.AND.KGDS2(20).EQ.255.AND.KGDS1(22).GT.0) THEN
     KGDS1(1:18)=KGDS2(1:18)
     KGDS1(2)=65535
     KGDS1(9)=65535
     KGDS1(19)=0
     KGDS1(20)=33
     KGDS1(21)=0
     DO J=1,KGDS2(3)
       KGDS1(21)=KGDS1(21)+KGDS1(21+J)
     ENDDO
!  PL PARAMETERS DEFAULT TO THOSE FOR NCEP GRIDS 37-44
   ELSEIF(MOD(KGDS2(11)/32,2).EQ.0.AND.KGDS2(20).EQ.255.AND. &
          KGDS1(22).LE.0.AND. &
          KGDS2(1).EQ.0.AND.KGDS2(2).EQ.73.AND.KGDS2(3).EQ.73.AND. &
          KGDS2(9).EQ.1250.AND.KGDS2(10).EQ.1250.AND. &
          (KGDS2(4).EQ.0.OR.KGDS2(4).EQ.-90000)) THEN
     KGDS1(1:18)=KGDS2(1:18)
     KGDS1(2)=65535
     KGDS1(9)=65535
     KGDS1(19)=0
     KGDS1(20)=33
     KGDS1(21)=3447
     IF(KGDS1(4).EQ.0) THEN
       KGDS1(22:94)=NPWAFS
     ELSE
       KGDS1(22:94)=NPWAFS(73:1:-1)
     ENDIF
   ELSE
     IRET=1
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  TRANSFORM FIELDS
 IF(IRET.EQ.0) THEN
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  EXPAND THINNED FIELDS TO FULL FIELDS
   IF(IDIR.EQ.1) THEN
     DO K=1,KM
       IS1=0
       IS2=0
       IB2(K)=0
       DO J=1,KGDS2(3)
         IM1=KGDS1(21+J)
         IM2=KGDS2(2)
         RAT1=REAL(IM1-1)/REAL(IM2-1)
         DO I=1,IM2
           X1=(I-1)*RAT1+1
           IA=X1
           IA=MIN(MAX(IA,1),IM1-1)
           IB=IA+1
           WA=IB-X1
           WB=X1-IA
           IF(IB1(K).EQ.0.OR.(L1(IS1+IA,K).AND.L1(IS1+IB,K))) THEN
             F2(IS2+I,K)=WA*F1(IS1+IA,K)+WB*F1(IS1+IB,K)
             L2(IS2+I,K)=.TRUE.
           ELSE
             F2(IS2+I,K)=0
             L2(IS2+I,K)=.FALSE.
             IB2(K)=1
           ENDIF
         ENDDO
         IS1=IS1+IM1
         IS2=IS2+IM2
       ENDDO
     ENDDO
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  CONTRACT FULL FIELDS TO THINNED FIELDS
   ELSEIF(IDIR.EQ.-1) THEN
     DO K=1,KM
       IS1=0
       IS2=0
       IB1(K)=0
       DO J=1,KGDS2(3)
         IM1=KGDS1(21+J)
         IM2=KGDS2(2)
         RAT2=REAL(IM2-1)/REAL(IM1-1)
         DO I=1,IM1
           X2=(I-1)*RAT2+1
           IA=X2
           IA=MIN(MAX(IA,1),IM2-1)
           IB=IA+1
           WA=IB-X2
           WB=X2-IA
           IF(IB2(K).EQ.0.OR.(L2(IS2+IA,K).AND.L2(IS2+IB,K))) THEN
             F1(IS1+I,K)=WA*F2(IS2+IA,K)+WB*F2(IS2+IB,K)
             L1(IS1+I,K)=.TRUE.
           ELSE
             F1(IS1+I,K)=0
             L1(IS1+I,K)=.FALSE.
             IB1(K)=1
           ENDIF
         ENDDO
         IS1=IS1+IM1
         IS2=IS2+IM2
       ENDDO
     ENDDO
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE IPXWAFS2
