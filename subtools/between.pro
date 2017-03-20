;+
; NAME:
;       between
;
; PURPOSE:
;       Returns 1 if a is between(equal) b and c ;  
;       Returns 0 if not
;
; CALLING SEQUENCE:
;       bla = between(a,b,c) 
;
; INPUTS:
;       b scalar       
;       c scalar       
;       a scalar or vector       

; OPTIONAL INPUTS:
;
; OUTPUTS:
;       1 or 0  byte,  same dimension as a
;
; PROCEDURE
;
; COMMON BLOCKS:
;       None.
;
; NOTES
;
; REFERENCES
; 
; AUTHOR and DATE:
;     Rene Preusker     20/01/99
;
; MODIFICATION HISTORY:
;
; :private:
;-
;

function between,a,b,c,not_include_upper=not_include_upper

	error_status = 0
	catch, error_status
	if (error_status ne 0) then begin
		catch, /cancel
		help, /last_message
		found = 0
		return, -1
	endif

IF keyword_set(not_include_upper) then begin
    case b lt c of 
     
    1:  return, (a ge b) * (a lt c)     

    else: return, (a ge c) * (a lt b) 
                
    endcase



ENDIF ELSE BEGIN

    case b lt c of 
     
    1:  return, (a ge b) * (a le c)     

    else: return, (a ge c) * (a le b) 
                
    endcase

ENDELSE    
    
end
