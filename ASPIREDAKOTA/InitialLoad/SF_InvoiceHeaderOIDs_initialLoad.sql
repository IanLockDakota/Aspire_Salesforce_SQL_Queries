MERGE INTO InvoiceHeader_ASPIRE__c_upsert AS Target
USING (SELECT DISTINCT
    NULL AS ID,
	c.contractOID AS contractOID__c,
	OppIDTable.opportunityID AS opportunity__c,
	IH.InvoiceHeaderOID AS InvoiceHeaderOID__c,
    IH.LastChangeOperator AS IHLastChangeOperator__c,
    IH.LastChangeDateTime AS IHLastChangeDatetime__c
FROM 
	[ASPIRESQL].[AspireDakota].[dbo].[Contract] C 
	LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[InvoiceHeader] IH ON c.ContractOid = IH.ContractOid
	LEFT OUTER JOIN 
	 (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                                  FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
                                  LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON c.ContractOid = OppIDTable.ref_oid
WHERE
	IH.InvoiceHeaderOID IS NOT NULL) AS Source
ON Target.Name = Source.InvoiceHeaderOID__c

WHEN MATCHED THEN
    UPDATE SET
        Target.opportunity__c = Source.opportunity__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        InvoiceHeaderOID__c,
        IHLastChangeOperator__c,
        IHLastChangeDatetime__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.InvoiceHeaderOID__c,
        Source.IHLastChangeOperator__c,
        Source.IHLastChangeDatetime__c
    );
