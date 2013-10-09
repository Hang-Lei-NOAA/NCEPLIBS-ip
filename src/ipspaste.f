 SUBROUTINE IPSPASTE(I1,I2,J1,J2,NF,MS,LS,FS,M,KGDS,L,F,IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  IPSPASTE   PASTE A SUBSECTOR OF A GRID BACK
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 1998-04-08
!
! ABSTRACT: THIS SUBPROGRAM PASTES A SUBSECTOR OF A GRID BACK
!           INTO THE ORIGINAL GRID.
!
! PROGRAM HISTORY LOG:
! 1999-04-08  IREDELL
! 2012-06-05  GAYNO   CORRECTED ARRAY INDEXING PROBLEM BETWEEN THE
!                     THE ORIGINAL AND SUBSECTOR GRIDS. 
!
! USAGE:    CALL IPSPASTE(I1,I2,J1,J2,NF,MS,LS,FS,M,KGDS,L,F,IRET)
!
!   INPUT ARGUMENT LIST:
!     I1       - INTEGER FIRST X POINT OF THE SECTOR
!                OR IF 0<=I2<I1,
!                THE TOTAL NUMBER OF NON-OVERLAPPING X SECTORS
!                OR IF 0<=I2<-I1,
!                THE NEGATIVE TOTAL NUMBER OF OVERLAPPING X SECTORS.
!     I2       - INTEGER LAST X POINT OF THE SECTOR
!                OR IF 0<=I2<ABS(I1), THE SECTOR NUMBER.
!     J1       - INTEGER FIRST Y POINT OF THE SECTOR
!                OR IF 0<=J2<J1,
!                THE TOTAL NUMBER OF NON-OVERLAPPING Y SECTORS
!                OR IF 0<=J2<-J1,
!                THE NEGATIVE TOTAL NUMBER OF OVERLAPPING Y SECTORS.
!     J2       - INTEGER LAST Y POINT OF THE SECTOR
!                OR IF 0<=J2<ABS(J1), THE SECTOR NUMBER.
!     NF       - INTEGER NUMBER OF FIELDS TO CUT
!     MS       - INTEGER FIRST DIMENSION OF INPUT FIELD ARRAYS
!     LS       - LOGICAL(1) (MS,NF) BITMAP FOR INPUT FIELD
!     FS       - REAL (MS,NF) DATA FOR INPUT FIELD
!     M        - INTEGER FIRST DIMENSION OF INPUT FIELD ARRAYS
!     KGDS     - INTEGER (200) OUTPUT GDS PARAMETERS
!
!   OUTPUT ARGUMENT LIST:
!     L        - LOGICAL(1) (M,NF) BITMAP FOR OUTPUT FIELD
!     F        - REAL (M,NF) DATA FOR OUTPUT FIELD
!     IRET     - INTEGER RETURN CODE
!                (0 IF SUCCESSFUL;
!                 71 IF UNSUPPORTED PROJECTION;
!                 72 IF INVALID SECTOR SPECIFICATION)
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,               INTENT(IN   ) :: I1,I2,J1,J2
 INTEGER,               INTENT(IN   ) :: KGDS(200), M, MS, NF
 INTEGER,               INTENT(  OUT) :: IRET
!
 LOGICAL(1),            INTENT(IN   ) :: LS(MS,NF)
 LOGICAL(1),            INTENT(  OUT) :: L(M,NF)
!
 REAL,                  INTENT(IN   ) :: FS(MS,NF)
 REAL,                  INTENT(  OUT) :: F(M,NF)
!
 INTEGER                              :: I1A,I2A,INA,J1A,J2A,JNA
 INTEGER                              :: K,KS,N,NS,NSCAN
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  COMPUTE ACTUAL SECTOR BOUNDARIES
 IF((KGDS(1).NE.0.AND.KGDS(1).NE.1.AND.KGDS(1).NE.3.AND. &
     KGDS(1).NE.4.AND.KGDS(1).NE.5).OR.KGDS(20).NE.255) THEN
   IRET=71
   RETURN
 ENDIF
 I1A=I1
 I2A=I2
 J1A=J1
 J2A=J2
 IF(I2.GE.0.AND.I1.GT.I2) THEN
   I1A=MIN(I2*((KGDS(2)-1)/I1+1)+1,KGDS(2)+1)
   I2A=MIN((I2+1)*((KGDS(2)-1)/I1+1),KGDS(2))
 ELSEIF(I2.GE.0.AND.-I1.GT.I2) THEN
   I1A=MIN(I2*((KGDS(2)-2)/(-I1)+1)+1,KGDS(2)+1)
   I2A=MIN((I2+1)*((KGDS(2)-2)/(-I1)+1)+1,KGDS(2))
 ENDIF
 IF(J2.GE.0.AND.J1.GT.J2) THEN
   J1A=MIN(J2*((KGDS(3)-1)/J1+1)+1,KGDS(3)+1)
   J2A=MIN((J2+1)*((KGDS(3)-1)/J1+1),KGDS(3))
 ELSEIF(J2.GE.0.AND.-J1.GT.J2) THEN
   J1A=MIN(J2*((KGDS(3)-2)/(-J1)+1)+1,KGDS(3)+1)
   J2A=MIN((J2+1)*((KGDS(3)-2)/(-J1)+1)+1,KGDS(3))
 ENDIF
 IF(I1A.LT.1.OR.I2A.GT.KGDS(2).OR.I1A.GT.I2A.OR. &
    J1A.LT.1.OR.J2A.GT.KGDS(3).OR.J1A.GT.J2A) THEN
   IRET=72
   RETURN
 ENDIF
 INA=I2A-I1A+1
 JNA=J2A-J1A+1
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  COPY BITMAPS AND DATA
 NS=INA*JNA
 NSCAN=MOD(KGDS(11)/32,2)
 DO N=1,NF
   DO KS=1,NS
     IF(NSCAN.EQ.0) THEN
       K=((KS-1)/INA+J1A-1)*KGDS(2)+MOD(KS-1,INA)+I1A
     ELSE
       K=((KS-1)/JNA+I1A-1)*KGDS(3)+MOD(KS-1,JNA)+J1A
     ENDIF
     L(K,N)=LS(KS,N)
     F(K,N)=FS(KS,N)
   ENDDO
 ENDDO
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE IPSPASTE
