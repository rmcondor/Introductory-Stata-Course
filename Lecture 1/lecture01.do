/**************************************************************
*PROJECT	:	INTRODUCTION TO STATA - LECTURE 1

*PURPUSE	: 	Explain some basic commands

*AUTHOR		:  	Ronny M. Condor (ronny.condor@unmsm.edu.pe)

*INPUTS		:	ENAHO - Many modules
*				- Módulo 01

*OUTPUTS	:	Summary statistics

*COMMENTS	:	
		
*****************************************************************/


* Estructura de trabajo

global root "C:\Users\Ronny\OneDrive - Universidad Nacional Mayor de San Marcos\Introduction to Stata\03_data"

global raw	"${root}\01_raw"
global codes	"${root}\02_codes"
global cleaned	"${root}\03_cleaned"
global analysis "${root}\04_analysis"
global results	"${root}\05_results"

* Abrir la base de datos

//Primera forma
use "C:\Users\Ronny\OneDrive - Universidad Nacional Mayor de San Marcos\Introduction to Stata\03_data\01_raw\740-Modulo01\enaho01-2021-100.dta", clear

//Segunda forma (más eficiente)
di "${raw}"
use "${raw}\740-Modulo01\enaho01-2021-100.dta", clear

*******************************************
* 			EXPLORACIÓN DE LA DATA
*******************************************

//Descripción de todas las variables
describe
d

count //Obs

//Descripción de variables específicas
describe result panel dominio tipodecuestionario
d nbi*

//Navegar en toda la base de datos
browse

//Navegar en los datos de variables específicas
br result panel dominio
edit //NO recomendable

//Diccionario de variables
codebook result

//Descriptivos
tabulate result
tab result mes

summarize p104
sum p104
sum p104 p104a

sum p104 p104a, detail

tabstat p104 p104a
tabstat p104 p104a, statistics(mean median n max min sd )

table dominio, c(mean p104)
table panel, by(result)


*******************************************
* 			CONDICIONALES
*******************************************

codebook dominio
sum p104 if dominio == 1 //Costa norte
sum p104 if dominio == 6 //Sierra sur

sum p104 if dominio != 8 //Todos excepto Lima Metropolitana

codebook estrato
tab p101 if estrato == 1 //Muy urbano
tab p101 if estrato == 8 //Muy rural

tab p101 if estrato == 1 & dominio == 1
tab p104 if dominio <= 3 
tab1 nbi*

tab result mes if dominio <= 3

tab result dominio if mes == "01" | mes == "03" 

bysort mes: tab dominio

*******************************************
* 			MODIFICAR LA DATA
*******************************************

* Filtrar la data
codebook result
keep if result == 1 //Solo encuestas completas
drop ticuest01 tipodecuestionario resultadorecod

* Generar variables
gen year = 2021
egen mean_dorm = mean(p104)

keep year mes conglome - panel nbi1 - nbi5 factor


*Ordenar
order year
order mes, after(year)

sort conglome vivienda hogar

* Creación de variables
replace mes = "Enero" if mes == "01"
replace mes = "Febrero" if mes == "02"
replace mes = "Marzo" if mes == "03"

gen urbano = 1 if estrato <= 6 //Hogares urbanos
replace urbano = 0 if estrato > 6 //Hogares rurales

drop urbano

recode estrato (1/6 = 1) (7/8 = 0), generate(urbano)

* Etiquetas
label variable urbano "Hogar urbano"

label define urbano_lab 1 "Urbano" 0 "Rural"
label values urbano urbano_lab

tab urbano

* Variables de identificación (keys)
global key_vars conglome vivienda hogar 
describe ${key_vars}

* Buscar duplicados
duplicates report ${key_vars}
duplicates report conglome vivienda //Hogares dentro de viviendas

duplicates tag conglome vivienda, gen(dup) //Para identificar los duplicados
drop dup

*Crear ID
egen id = concat(${key_vars})
order id, a(mes)
