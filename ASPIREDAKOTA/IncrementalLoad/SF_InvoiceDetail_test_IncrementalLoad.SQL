/*
Name: InvoiceDetail

ASPIRE SQLS Table Dependencies:
    - Contract
    - InvoiceDetail
    - TransactionCode
    - LTIValues
    - InvoiceHeader

Salesforce Backups Table Dependencies:
    - Invoice_ASPIRE__c_upsert

SF Object Dependencies:
    - Invoice_ASPIRE__c

Last change: 11/30/2023

Other Notes:
    - START and END parameters to set timeframe of data to be pulled 
*/

-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

---- MERGE
MERGE INTO Invoice_ASPIRE__c_upsert AS Target
USING (SELECT 
NULL AS ID,
C.ContractOID AS ContractOID__c,
OppIDTable.opportunityID AS Opportunity__c,
ID.InvoiceHeaderOid AS InvoiceHeaderOID__c, /* MISSING */
ID.InvoiceDetailOid AS InvoiceDetailOID__c,
ID.InvoiceDetailOid AS Name,
ID.OpenClosedOID AS PaymentMethodOID__c,
LTVI.data_value AS InvoicePaymentMethod__c, /* MISSING */
ID.TransactionCodeOID AS TransactionCode__C,
TC.Description AS Description__c,
ID.OriginalDueAmount AS OriginalDueAmount__c,
ID.CurrentDueAmount AS CurrentDueAmount__c,
IH.InvoiceDate AS InvoiceDate__C, /* MISSING */
IH.DueDate AS DueDate__c,
ID.IsPaid AS IsPaid__C, /* MISSING */
ID.LastChangeOperator AS LastChangeOperator__c, /* MISSING */
ID.LastChangeDateTime  AS LastChangeDatetime__c /* MISSING */


FROM [ASPIRESQL].[AspireDakota].[dbo].[Contract] C LEFT OUTER JOIN 
[ASPIRESQL].[AspireDakota].[dbo].[InvoiceDetail] ID LEFT OUTER JOIN
[ASPIRESQL].[AspireDakota].[dbo].[TransactionCode] TC ON ID.TransactionCodeOid = TC.TransactionCodeOid ON C.ContractOid = ID.ContractOid  LEFT OUTER JOIN
[ASPIRESQL].[AspireDakota].[dbo].[LTIValues] LTVI ON LTVI.OID = ID.OpenClosedOid LEFT OUTER JOIN
[ASPIRESQL].[AspireDakota].[dbo].[InvoiceHeader] IH ON IH.InvoiceHeaderOID = ID.InvoiceHeaderOID LEFT OUTER JOIN
                                
                                /* Pulling Oppurtunity ID */

                                (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
                                  FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
                                  LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON c.ContractOid = OppIDTable.ref_oid

/*below is where datetime comparison is done*/
WHERE (C.IsBooked = 1) AND (C.CompanyOid = 1) AND (IH.IsPosted = 1) AND (ID.LastChangeDateTime BETWEEN @start AND @end)) AS Source
ON Target.InvoiceDetailOID__c = Source.InvoiceDetailOID__c

/*Upsert capabilities*/

WHEN MATCHED THEN
    UPDATE SET
        Target.InvoiceHeaderOID__c = Source.InvoiceHeaderOID__c,
        Target.Name = Source.Name,
        Target.InvoicePaymentMethod__c = Source.InvoicePaymentMethod__c,
        Target.PaymentMethodOID__c = Source.PaymentMethodOID__c,
        Target.TransactionCode__C = Source.TransactionCode__C,
        Target.Description__c = Source.Description__c,
        Target.OriginalDueAmount__c = Source.OriginalDueAmount__c,
        Target.CurrentDueAmount__c = Source.CurrentDueAmount__c,
        Target.InvoiceDate__C = Source.InvoiceDate__C,
        Target.DueDate__c = Source.DueDate__c,
        Target.IsPaid__C = Source.IsPaid__C,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c,
        Target.LastChangeDatetime__c = Source.LastChangeDatetime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        InvoiceHeaderOID__c,
        InvoiceDetailOID__c,
        Name,
        PaymentMethodOID__c,
        InvoicePaymentMethod__c,
        TransactionCode__C,
        Description__c,
        OriginalDueAmount__c,
        CurrentDueAmount__c,
        InvoiceDate__C,
        DueDate__c,
        IsPaid__C,
        LastChangeOperator__c,
        LastChangeDatetime__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.InvoiceHeaderOID__c, 
        Source.InvoiceDetailOID__c,
        Source.Name,
        Source.PaymentMethodOID__c,
        Source.InvoicePaymentMethod__c,
        Source.TransactionCode__C,
        Source.Description__c,
        Source.OriginalDueAmount__c,
        Source.CurrentDueAmount__c,
        Source.InvoiceDate__C,
        Source.DueDate__c,
        Source.IsPaid__C,
        Source.LastChangeOperator__c,
        Source.LastChangeDatetime__c
    );