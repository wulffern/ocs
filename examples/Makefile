######################################################################
##        Copyright (c) 2014 Carsten Wulff Software, Norway 
## ###################################################################
## Created       : wulff at 2014-11-14
## ###################################################################
## Licensed under the Apache License, Version 2.0 (the "License")
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
## 
##     http://www.apache.org/licenses/LICENSE-2.0
## 
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
######################################################################



DEFINE ?=
CMD=oc
CORNERS ?=
OPT ?=
PARAMS ?=
M=Auto simulation commit

ocean:
	-${CMD} ocean ${TB} --corners "${CORNERS}" --config "${VIEW}" --define "${DEFINE}" --run ${OPT}
	-${MAKE} html


status:
	${CMD} status ${TB}_output ${OPT}

html:
	-${CMD} html --param "${PARAMS}" results/${TB}.*.csv --fileregex "${TB}." --outfile results/${TB}.html ${OPT}

extract:
	-${CMD} extract ${TB}_output/${TB}.*.log ${OPT}


typical:
	${MAKE} ocean CORNERS=typical 

tfs:
	${MAKE} ocean CORNERS="typical fast slow"

etc:
	${MAKE} ocean CORNERS="etc"




