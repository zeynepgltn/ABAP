*&---------------------------------------------------------------------*
*& Report ZGZ_P003
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p003.

PARAMETERS: p_num TYPE i.

DATA: i TYPE i VALUE 1,
      j TYPE i VALUE 0,
      k TYPE i.

WHILE i <= p_num.
  j = 0.
  WHILE j < i.
    j += 1.
    WRITE '*'.
  ENDWHILE.
  i += 1.
  WRITE /.
ENDWHILE.


i = 0.
j = p_num.

WHILE i < p_num.
  i += 1.
  j = p_num - i.
  WHILE j > 0.
    WRITE ' '.
    j -= 1.
  ENDWHILE.

  DO i TIMES.
    WRITE '*'.
  ENDDO.
  WRITE /.
ENDWHILE.


i = 1.

WHILE i <= p_num.
  j = p_num - i.
  DO j TIMES.
    WRITE ' '.
  ENDDO.

  k = 2 * i - 1.
  DO k TIMES.
    WRITE '*'.
  ENDDO.
  WRITE /.
  i += 1.
ENDWHILE.

WRITE /.

i = p_num.
j = 0.

WHILE i > 0.

  DO j TIMES.
    WRITE ' '.
  ENDDO.
  j += 1.

  k = 2 * i - 1.
  DO k TIMES.
    WRITE '*'.
  ENDDO.
  i -= 1.

  WRITE /.
ENDWHILE.




i = 1.
WHILE i <= p_num.

  j = p_num - i.
  DO j TIMES.
    WRITE ' '.
  ENDDO.

  k = 2 * i - 1.
  DO k TIMES.
    WRITE '*'.
  ENDDO.

  WRITE /.
  i += 1.

ENDWHILE.

i = p_num - 1.

WHILE i > 0.

  j = p_num - i.
  DO j TIMES.
    WRITE ' '.
  ENDDO.

  k = 2 * i - 1.
  DO k TIMES.
    WRITE '*'.
  ENDDO.

  WRITE /.
  i -= 1.

ENDWHILE.
