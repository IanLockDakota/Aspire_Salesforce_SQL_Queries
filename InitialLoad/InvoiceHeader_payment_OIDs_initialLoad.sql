

MERGE INTO InvoiceHeader_ASPIRE__c_upsert AS Target
USING (SELECT DISTINCT
    NULL AS ID,
	c.contractOID AS contractOID__c,
	OppIDTable.opportunityID AS opportunity__c,
	ID.InvoiceHeaderOID AS InvoiceHeaderOID__c,
	pyid.paymentOID AS paymentOID__c
FROM 
	[ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] C 
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakotaTest].[dbo].[InvoiceDetail] id ON id.ContractOid = c.ContractOid
	LEFT OUTER JOIN 
	 (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                                  FROM [ASPIRESQL].[AspireDakotaTest].[dbo].[GenericField] GF 
                                  LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON c.ContractOid = OppIDTable.ref_oid LEFT OUTER JOIN
	(SELECT crb.InvoiceHeaderOid, crh.PaymentOid
	FROM
		[ASPIRESQL].[AspireDakotaTest].[dbo].[CashReceiptBillable] crb LEFT OUTER JOIN
		[ASPIRESQL].[AspireDakotaTest].[dbo].[CashReceiptHeader] crh ON crb.CashReceiptHeaderOid=crh.CashReceiptHeaderOid) AS pyid ON id.invoiceHeaderOID = pyid.invoiceHeaderOID) AS Source
ON Target.InvoiceHeaderOID__c = Source.InvoiceHeaderOID__c

WHEN MATCHED THEN
    UPDATE SET
        Target.opportunity__c = Source.opportunity__c,
        Target.Paymentoid__c = Source.Paymentoid__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        InvoiceHeaderOID__c,
        PaymentOID__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.InvoiceHeaderOID__c,
        Source.PaymentOID__c
    );
