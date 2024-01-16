/*
Name: Payment_InvoiceDetail

ASPIRE SQLS Table Dependencies:
    - Payment
    - LTIValues
    - CashReceiptHeader
    - CashReceiptBillable
    - CashReceiptDetail
    - Contract
    - InvoiceDetail
    - GenericField
    - cdataGenericValue

Salesforce Backups Table Dependencies:
    - Payment_ASPIRE__c_upsert

SF Object Dependencies:
    - Payment_ASPIRE__c

Last change: 11/30/2023

Other Notes:
    - Does not use parameters to set date frame for data being pulled
    - Missing ContractOID, OppId, InvoiceHeaderOid, InvoiceDetailOid. IsPosted, CRDLastChangeOpp, CRDLastChangeDT
*/

-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

----MERGE
MERGE INTO Payment_ASPIRE__c_upsert AS Target
USING (
    SELECT
        NULL as ID,
        p.ContractOID AS ContractOid__c,
        OppIDTable.opportunityID AS Opportunity__c,
        P.PaymentOid AS PaymentOid__c,
        P.ReferenceNumber AS ReferenceNumber__c,
        ID.InvoiceHeaderOid AS InvoiceHeaderOid__c,
        ID.InvoiceDetailOid AS InvoiceDetailOid__c,
        CRD.CashReceiptDetailOID AS CashReceiptDetailOID__c,
        LTIV.descr AS descr__c,
        CRD.AppliedAmount AS AppliedAmount__c,
        P.PostDate AS PostDate__c,
        P.EffectiveDate AS EffectiveDate__c,
        P.IsPosted AS IsPosted__c,
        P.IsReturned AS IsReturned__c,
        CRD.LastChangeOperator AS CRDLastChangeOperator__c,
        CRD.LastChangeDateTime AS CRDLastChangeDateTime__c,
        P.LastChangeDateTime AS PaymentLastChangeDateTime__c

    FROM [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[Payment] P
    LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[LTIValues] LTIV ON LTIV.OID = P.PaymentMethodOid
    LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[CashReceiptHeader] CRH ON CRH.PaymentOID = P.PaymentOID
    LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[CashReceiptBillable] CRB ON CRB.CashReceiptHeaderOID = CRH.CashReceiptHeaderOID
    LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[CashReceiptDetail] CRD ON CRD.CashReceiptBillableOid = CRB.CashReceiptBillableOid
    INNER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[Contract] C ON C.ContractOid = P.ContractOid
    LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[InvoiceDetail] ID ON ID.InvoiceDetailOid = CRD.InvoiceDetailOid
    LEFT OUTER JOIN (
        SELECT
            c.ContractOID,
            GV.ref_oid,
            GF.descr,
            ISNULL(GV.field_value, 'NULL') AS opportunityID
        FROM [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[GenericField] GF
        LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid
        LEFT OUTER JOIN [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[Contract] c ON c.ContractOid = GV.ref_oid
        WHERE GF.oid = 23
        GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
    ) AS OppIDTable ON C.ContractOid = OppIDTable.ref_oid

    WHERE (C.IsBooked = 1) AND (C.CompanyOid = 1) AND (P.IsPosted = 1) AND ((CRD.LastChangeDateTime BETWEEN @start AND @end) OR (P.LastChangeDateTime BETWEEN @start AND @end))) AS Source

ON Target.CashReceiptDetailOID__c = Source.CashReceiptDetailOID__c

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.PaymentOid__c = Source.PaymentOid__c,
        Target.ReferenceNumber__c = Source.ReferenceNumber__c,
        Target.InvoiceHeaderOid__c = Source.InvoiceHeaderOid__c,
        Target.InvoiceDetailOid__c = Source.InvoiceDetailOid__c,
        Target.descr__c = Source.descr__c,
        Target.AppliedAmount__c = Source.AppliedAmount__c,
        Target.PostDate__c = Source.PostDate__c,
        Target.EffectiveDate__c = Source.EffectiveDate__c,
        Target.IsPosted__c = Source.IsPosted__c,
        Target.IsReturned__c = Source.IsReturned__c,
        Target.CRDLastChangeOperator__c = Source.CRDLastChangeOperator__c,
        Target.CRDLastChangeDateTime__c = Source.CRDLastChangeDateTime__c,
        Target.PaymentLastChangeDateTime__c = Source.PaymentLastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        PaymentOid__c,
        ReferenceNumber__c,
        InvoiceHeaderOid__c,
        InvoiceDetailOid__c,
        CashReceiptDetailOID__c,
        descr__c,
        AppliedAmount__c,
        PostDate__c,
        EffectiveDate__c,
        IsPosted__c,
        IsReturned__c,
        CRDLastChangeOperator__c,
        CRDLastChangeDateTime__c,
        PaymentLastChangeDateTime__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.PaymentOid__c,
        Source.ReferenceNumber__c,
        Source.InvoiceHeaderOid__c,
        Source.InvoiceDetailOid__c,
        Source.CashReceiptDetailOID__c,
        Source.descr__c,
        Source.AppliedAmount__c,
        Source.PostDate__c,
        Source.EffectiveDate__c,
        Source.IsPosted__c,
        Source.IsReturned__c,
        Source.CRDLastChangeOperator__c,
        Source.CRDLastChangeDateTime__c,
        Source.PaymentLastChangeDateTime__c
    );