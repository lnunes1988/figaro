#INCLUDE "TOTVS.CH"
#INCLUDE "APWEBSRV.CH"
#INCLUDE "RESTFUL.CH"
#Include "TopConn.ch"
#Define STR_PULA		Chr(13)+Chr(10)


User Function Figaro()
Return .T.


WSRESTFUL Figaro DESCRIPTION EncodeUTF8("Serviço de extração de dados do Protheus") 

	WSDATA cArqLocal		As String Optional
	WSDATA cFileName		As String Optional
	WSDATA cFile			As String Optional
	WSDATA pedido			As String Optional
	WSDATA cQuery			As String Optional

	WSMETHOD GET DESCRIPTION "Retorna medição de contrato" WSSYNTAX "/TelePDF"  PATH "/TelePDF"
	WSMETHOD POST DESCRIPTION "Retorna um JSON a partir de uma script SQL" WSSYNTAX "/TeleJson"  PATH "/TeleJson"
END WSRESTFUL

WSMETHOD GET  PATHPARAM cQuery WSSERVICE Figaro

	local oJson
	local ret

	::SetContentType("application/json")
	::SetHeader('Access-Control-Allow-Credentials' , "true")

	oJson := JsonObject():new()
	conout("Query:"+ValType(::cQuery))
	cTelJson:= RepPrint(::cQuery)
	
	ret := oJson:fromJson(cTelJson)
	CONOUT(ValType(ret)) 

	if ValType(ret) == "U" 
		Conout("JsonObject populado com sucesso")
	else
		Conout("Falha ao popular JsonObject. Erro: " + ret)
	endif
	IF 0==1
		fRepPrint()
	Endif

	cJson := FWJsonSerialize(oJson, .F., .F., .T.)
	::SetResponse(oJson)
Return (.t.)


WSMETHOD POST  PATHPARAM cQuery WSSERVICE Figaro

	local oJson
	local ret
	::SetContentType("application/json")
	::SetHeader('Access-Control-Allow-Credentials' , "true")

	oJson := JsonObject():new()
	conout("Query:"+ValType(::cQuery))
	cTelJson:= RepPrint(::cQuery)
	
	ret := oJson:fromJson(cTelJson)
	CONOUT(ValType(ret)) 

	if ValType(ret) == "U" 
		Conout("JsonObject populado com sucesso")
	else
		Conout("Falha ao popular JsonObject. Erro: " + ret)
	endif
	IF 0==1
		fRepPrint()
	Endif

	cJson := FWJsonSerialize(oJson, .F., .F., .T.)
	::SetResponse(oJson)

Return(.T.)

Static Function fRepPrint()
	Local aArea    := GetArea()
	Local cQryAux  := ""
	
	//Pegando as seções do relatório
	
	//Montando consulta de dados
	cQryAux := ""
	cQryAux += "SELECT CN9_NUMERO, CN9_DTFIM, CN9_VLATU, CN9_REVISA, CN9_SALDO, CNC_CODIGO, CNC_LOJA, CN9_SITUAC, CN9_CODOBJ, A2_NOME "		+ STR_PULA
	cQryAux += "FROM CN9010 CN9 "		+ STR_PULA
    cQryAux += "INNER JOIN CNC010 CNC "		+ STR_PULA
    cQryAux += "ON  CN9_NUMERO = CNC_NUMERO AND "		+ STR_PULA
    cQryAux += "CN9_REVISA = CNC_REVISA "		+ STR_PULA
    cQryAux += "INNER JOIN SA2010 SA2 ON "		+ STR_PULA
    cQryAux += "CNC_CODIGO = A2_COD AND  "		+ STR_PULA
    cQryAux += "CNC_LOJA = A2_LOJA  "		+ STR_PULA
	cQryAux += "WHERE   (CN9_SITUAC = '05' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = '02' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = '03' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = '04' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = '06' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = '07' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = '09' OR"		+ STR_PULA
	cQryAux += "        CN9_SITUAC = 'A') AND"		+ STR_PULA
	cQryAux += "        CN9_ESPCTR = '1' AND"		+ STR_PULA
	cQryAux += "        CN9.D_E_L_E_T_ = ' ' AND "		+ STR_PULA
	cQryAux += "        CNC.D_E_L_E_T_ = ' ' AND "		+ STR_PULA
	cQryAux += "        SA2.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "ORDER BY CN9_NUMERO, CN9_REVISA"		+ STR_PULA
	cQryAux := ChangeQuery(cQryAux)
	
	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	//Count to nTotal
	TCSetField("QRY_AUX", "CN9_DTFIM", "D")
	n=1
	cLinha:='{"Contratos": ['+ STR_PULA
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		if n!=1
		cLinha+=','+ STR_PULA
		Endif
		n++
		cLinha+='{'
		cLinha += '"Contrato":"'		+ QRY_AUX->CN9_NUMERO				+'",'+ STR_PULA
		cLinha += '"Data Final":"'		+ DToC(QRY_AUX->CN9_DTFIM)				+'",'+ STR_PULA
		cLinha += '"Valor Global":'		+ cValToChar(QRY_AUX->CN9_VLATU)	+',' + STR_PULA
		cLinha += '"Revisao":"'			+ QRY_AUX->CN9_REVISA				+'",'+ STR_PULA
		cLinha += '"Saldo":'			+ cValToChar(QRY_AUX->CN9_SALDO)	+',' + STR_PULA
		cLinha += '"Código":"'			+ QRY_AUX->CNC_CODIGO				+'",'+ STR_PULA
		cLinha += '"Fornecedor":"'		+ Alltrim(QRY_AUX->A2_NOME)					+'",'+ STR_PULA
		cLinha += '"Situação":"'		+ QRY_AUX->CN9_SITUAC				+'"' + STR_PULA
		cLinha += '}'
		QRY_AUX->(DbSkip())
	EndDo
	cLinha += ']}'
	QRY_AUX->(DbCloseArea())
	RestArea(aArea)
Return(cLinha)


	Static Function REPPRINT(cQryAux)
	Local i
	Local aEstruct
	Local c
	Local aArea    := GetArea()  
    RpcSetType(3)
    RpcSetEnv("01", "01",,,"FAT")
    nModulo := 05

    If Empty(cQryAux)
		cQryAux := "SELECT TOP 10 * FROM SA1010 SA1 WHERE SA1.D_E_L_E_T_ = ' '"
    EndIf
	cQryAux := ChangeQuery(cQryAux)
    TCQuery cQryAux New Alias "QRY_AUX"
	aEstruct:={}
    for i:=1 to 255
        cCampo := FieldName( i ) 
        if Len(cCampo)==0 
            Conout("Finalizou a lista de campos "+ cValToChar(i))
            Exit 
        Elseif LEN(TamSX3(cCampo))==0
            If(substr(cCampo,1,2)='__')
                Conout("Campo customizado: "+cCampo) 
                aAdd(aEstruct,{cCampo,cCampo,"C"})
            Else             
                Conout("Campo de nome:"+cCampo) 
                aAdd(aEstruct,{cCampo,cCampo,"N"})
            Endif
            Loop
        EndIf
		aa:=TamSX3(cCampo)
        aAdd(aEstruct,{Alltrim(FWX3Titulo(cCampo)),cCampo,aa[3]})
        
        If aa[3]=="D"
            TCSetField("QRY_AUX", cCampo, "D")
            Conout("Alterou para DATA")
        EndIf

    Next
    
	n=1
	c:=1
    cLinhaAux:=''
	cLinha:='{"Tabela": ['+ STR_PULA
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		if n!=1
		cLinhaAux+=','+ STR_PULA
		Endif
		n++
		cLinhaAux+='{'
		nCol := 1	
		For c:=1 To Len(aEstruct)
			if c == Len(aEstruct)
				cDeli:=''//Quando for a última não coloca virgula
			Else
				cDeli:=','
			Endif
			//conout("")
            cColuna := aEstruct[c,1]
            If cColuna $ cLinhaAux
                cColuna := aEstruct[c,1]+" "+cValToChar(nCol++)
            Endif
			If aEstruct[c,3]=='C'
				cLinhaAux += '"'+cColuna+'":"'		+ oemtoAnsi(Alltrim(FieldGet(c)))			+	'"'	+cDeli+ STR_PULA
			Elseif aEstruct[c,3]=='D'
				//conout("-->"+aEstruct[c,1]+' - ' + cValToChar(c)+"-"+iIf(c==223,Alltrim(FieldGet(c)),DToC(FieldGet(c))))
				cLinhaAux += '"'+cColuna+'":"'		+ DToC(FieldGet(c))		+	'"'	+cDeli+ STR_PULA
			Elseif aEstruct[c,3]=='N'
				cLinhaAux += '"'+cColuna+'":'		+ cValToChar(FieldGet(c))		+cDeli+ STR_PULA
			EndIf
			
		Next
		cLinhaAux += '}'
		QRY_AUX->(DbSkip())
        cLinha+=cLinhaAux
        cLinhaAux:=''
		nCol:=0
	EndDo
	cLinha += ']}'
	QRY_AUX->(DbCloseArea()) 
	RestArea(aArea) 
	cLinha:=EncodeUtf8(cLinha )
Return(cLinha)
