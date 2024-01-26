SELECT
    TD.ContractOID,
    TD.ContractItemOID,
	TD.ParentInvoiceDetailOid,
    TD.ContractItemTypeOID,
    TD.TaxProductOID,
	TP.Description,
	LTIV2.descr AS TaxJurisdictionOID,
    TD.AppliedTaxabilityOID,
    TD.AppliedTaxPaymentTypeOID,
    TD.TaxableAmount,
    TD.TaxRate,
    TD.TaxAmount,
    TD.AppliedTaxAmount,
    TD.PaymentDate,
    TD.TaxCodeOID,
    TEA.TaxExceptionOID,
    TED.TaxCodeOID,
    TED.JurisdictionOID,
    TED.TaxabilityOID,
    TED.RateOverride,
    TED.RateAdjustment,
	st.name as stateName,
	TC.Code,
	TC.Description,
	TR.TaxType,
	TR.Description,
	TR.TaxRate,
	TR.MinTaxableAmount,
	TR.MaxTaxableAmount
FROM
    TaxDetailFinalized TD
	LEFT OUTER JOIN ltivalues LTIV2 ON TD.TaxJurisdictionOID = LTIV2.oid
	LEFT OUTER JOIN TaxProduct TP ON TD.TaxProductOid = TP.TaxProductOid
    LEFT OUTER JOIN TaxExceptionAsset TEA ON TD.ContractItemOID = TEA.ContractItemOID
    LEFT OUTER JOIN TaxException TE ON TEA.TaxExceptionOID = TE.TaxExceptionOID
    LEFT OUTER JOIN TaxExceptionDetail TED ON TEA.TaxExceptionOID = TED.TaxExceptionOID
	--LEFT OUTER JOIN ContractEquipment CE ON TD.ContractItemOid = CE.
	LEFT OUTER JOIN TaxCode TC ON TD.TaxCodeOid = TC.TaxCodeOid
	LEFT OUTER JOIN state st ON tc.StateOid = st.oid
	LEFT OUTER JOIN TaxRate TR ON TC.TaxCodeOid = TR.TaxCodeOid
WHERE
    (TE.inactiveDate IS NULL) AND (TD.ContractOID <> 0)
ORDER BY
	TD.ContractOID, TD.ContractItemOID, TD.PaymentDate;

---------------------------------------------------------------------------
-------TaxLTIValues------------------
SELECT
	table_key,
	oid,
	data_value
FROM LTIValues
WHERE table_key LIKE '%Tax%'


-------------TaxCodes---------------
SELECT DISTINCT
	TC.Code,
	LTI2.data_value AS Jurisdiction,
	LTI3.data_value AS Administration,
	TC.Description,
	TR.TaxType,
	TR.Description,
	TR.TaxRate,
	TR.MinTaxableAmount,
	TR.MaxTaxableAmount
FROM
	TaxCode TC
	LEFT OUTER JOIN TaxRate TR ON TC.TaxCodeOid = TR.TaxCodeOid
	LEFT OUTER JOIN LTIValues LTI2 ON TC.JurisdictionOid = LTI2.oid
	LEFT OUTER JOIN LTIValues LTI3 ON TC.AdministrationOid = LTI3.oid


---------------------TaxDetail-------------------------------
SELECT
    TD.ContractOID,
    TD.ContractItemOID,
	TD.ParentInvoiceDetailOid,
    TD.ContractItemTypeOID,
    TD.TaxProductOID,
	TP.Description,
    LTI1.data_value,
	LTI2.data_value,
    TD.TaxableAmount,
    TD.TaxRate,
    TD.TaxAmount,
    TD.AppliedTaxAmount,
    TD.PaymentDate,
    TD.TaxCodeOID
FROM
    TaxDetailFinalized TD
	LEFT OUTER JOIN TaxProduct TP ON TD.TaxProductOid = TP.TaxProductOid
	LEFT OUTER JOIN LTIValues LTI1 ON TD.AppliedTaxabilityOID = LTI1.oid
	LEFT OUTER JOIN LTIValues LTI2 ON TD.AppliedTaxPaymentTypeOid = LTI2.oid
WHERE
	(TD.ContractOid IS NOT NULL) AND (TD.ContractOid >= 2) AND (td.contractOID = 10) AND (TD.ContractItemTypeOID IN (1, 9))--AND (TD.TaxProductOid NOT IN ('1', '5'))
ORDER BY
	TD.ContractOid, TD.ContractItemOid

-----------------Combined-----------------------------

SELECT
	Detail.ContractOid,
	ID.InvoiceHeaderOid,
	Detail.ParentInvoiceDetailOid,
	Detail.AppliedTaxability
FROM
	(SELECT
		TD.ContractOID,
		TD.ContractItemOID,
		TD.ParentInvoiceDetailOid,
		TD.ContractItemTypeOID,
		TD.TaxProductOID,
		TP.Description,
		LTI1.data_value as AppliedTaxability,
		LTI2.data_value as AppliedTaxPaymentType,
		TD.TaxableAmount,
		TD.TaxRate,
		TD.TaxAmount,
		TD.AppliedTaxAmount,
		TD.PaymentDate,
		TD.TaxCodeOID
	FROM
		TaxDetailFinalized TD
		LEFT OUTER JOIN TaxProduct TP ON TD.TaxProductOid = TP.TaxProductOid
		LEFT OUTER JOIN LTIValues LTI1 ON TD.AppliedTaxabilityOID = LTI1.oid
		LEFT OUTER JOIN LTIValues LTI2 ON TD.AppliedTaxPaymentTypeOid = LTI2.oid
	WHERE
		(TD.ContractOid IS NOT NULL) AND (TD.ContractOid >= 2) AND (td.contractOID = 10) AND (TD.ContractItemTypeOID IN (1, 9))) AS Detail
	LEFT OUTER JOIN
	(SELECT DISTINCT
		TC.Code,
		LTI2.data_value AS Jurisdiction,
		LTI3.data_value AS Administration,
		TC.Description,
		TR.TaxType,
		TR.Description as TaxTypeDescription,
		TR.TaxRate,
		TR.MinTaxableAmount,
		TR.MaxTaxableAmount
	FROM
		TaxCode TC
		LEFT OUTER JOIN TaxRate TR ON TC.TaxCodeOid = TR.TaxCodeOid
		LEFT OUTER JOIN LTIValues LTI2 ON TC.JurisdictionOid = LTI2.oid
		LEFT OUTER JOIN LTIValues LTI3 ON TC.AdministrationOid = LTI3.oid) AS Code ON Detail.TaxCodeOID = Code.Code
	LEFT OUTER JOIN
		InvoiceDetail ID ON Detail.ParentInvoiceDetailOid = ID.InvoiceDetailOID