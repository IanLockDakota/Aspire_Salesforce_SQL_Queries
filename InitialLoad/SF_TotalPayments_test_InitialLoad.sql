/*
Name: NetInvestment

ASPIRE SQLS Table Dependencies:
   - ContractTerm
   - PaymentStream
   - Contract
   - InvoiceDetail
   - GenericField
   - cdataGenericValue


Salesforce Backups Table Dependencies:
    - Total_Payments_ASPIRE__c_upsert

SF Object Dependencies:
    - Total_Payments_ASPIRE__c

Last change: 12/5/2023

Other Notes:
    - I believe termatDPD is the only field that needs to be added.
*/


MERGE INTO Total_Payments_ASPIRE__c_upsert AS Target
USING (SELECT
    NULL AS ID, 
    Contract.ContractOid AS ContractOID__c,
    OppIDTable.OpportunityID AS Opportunity__c,
    TtlPayStream.TtlSchPymts AS TtlSchPymts__c,
    InvoicedPymnts.TtlSchPymts as InvPymtsAmount__c,
    UnInvoicedPymnts.TtlSchPymts AS UninvPymtsAmount__c,
    InvoicedPymnts.startDate AS FirstPayment__c,
    CASE
		WHEN UnInvoicedPymnts.startDate > GETDATE() THEN InvoicedPymnts.startDate
		WHEN UnInvoicedPymnts.startDate < GETDATE() AND contract.isTerminated = 1 THEN NULL
		WHEN UnInvoicedPymnts.startDate <= GETDATE() AND contract.isTerminated = 0 AND MONTH(UnInvoicedPymnts.startDate) = 12 THEN DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()) + 1, 1, DAY(UnInvoicedPymnts.startDate)))
		WHEN UnInvoicedPymnts.startDate <= GETDATE() AND contract.isTerminated = 0 THEN DATEADD(MONTH, 1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), DAY(UnInvoicedPymnts.startDate)))
		ELSE NULL
	END AS NextPayment__c,
    ContractTerm.MaturityDate AS MaturityDate__c,
    InvoicedPymnts.LastChangeDateTime AS LastChangeDateTime__c,
    InvoicedPymnts.LastChangeOperator AS LastChangeOperator__c
FROM
    [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[ContractTerm] INNER JOIN
    (
        SELECT
            PaymentStream.ContractTermOid,
            SUM(PaymentStream.Occurrences) AS TtlSchPymts
        FROM
            [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[PaymentStream]
        GROUP BY
            PaymentStream.ContractTermOid
    ) AS TtlPayStream ON ContractTerm.ContractTermOid = TtlPayStream.ContractTermOid
INNER JOIN
    [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[Contract] ON ContractTerm.ContractOid = Contract.ContractOid INNER JOIN
    (
        SELECT
            PaymentStream.ContractTermOid,
            MIN(PaymentStream.Startdate) as startDate,
            SUM(PaymentStream.Occurrences) AS TtlSchPymts,
            LastChangeDateTime,
            LastChangeOperator
        FROM
            [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[PaymentStream]
        WHERE
            (isInvoiced = 1) AND (ContractTermOID IS NOT NULL)
        GROUP BY
            PaymentStream.ContractTermOid, LastChangeDateTime, LastChangeOperator
    ) AS InvoicedPymnts ON ContractTerm.ContractTermOID = InvoicedPymnts.ContractTermOID
INNER JOIN
    (
        SELECT
            PaymentStream.ContractTermOid,
            MAX(PaymentStream.Startdate) as startDate,
            SUM(PaymentStream.Occurrences) AS TtlSchPymts,
            LastChangeDateTime,
            LastChangeOperator
        FROM
            [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[PaymentStream]
        WHERE
            (isInvoiced = 0) AND (ContractTermOID IS NOT NULL)
        GROUP BY
            PaymentStream.ContractTermOid, LastChangeDateTime, LastChangeOperator
    ) AS UnInvoicedPymnts ON ContractTerm.ContractTermOID = UnInvoicedPymnts.ContractTermOID INNER JOIN
    (
        SELECT
            c.ContractOID,
            GV.ref_oid,
            GF.descr,
            ISNULL((GV.field_value), 'NULL') AS OpportunityID
        FROM
            [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[GenericField] GF 
        LEFT OUTER JOIN
            [ASPIRESQL].[ASPIREDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid
        LEFT OUTER JOIN
            [ASPIRESQL].[ASPIREDakotaTEST].[dbo].[Contract] c ON c.ContractOid = gv.ref_oid
        WHERE
            GF.oid = 23
        GROUP BY
            c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
    ) AS OppIDTable ON OppIDTable.contractOid = Contract.contractOID
WHERE
    (Contract.CompanyOid = 1) AND (Contract.IsBooked = 1)) AS Source
ON Target.Opportunity__c = Source.Opportunity__c

/*Upsert capabilities*/

WHEN MATCHED THEN
    UPDATE SET
        Target.TtlSchPymts__c = Source.TtlSchPymts__c,
        Target.InvPymtsAmount__c = Source.InvPymtsAmount__c,
        Target.UninvPymtsAmount__c = Source.UninvPymtsAmount__c,
        Target.FirstPayment__c = Source.FirstPayment__c,
        Target.NextPayment__c = Source.NextPayment__c,
        Target.MaturityDate__c = Source.MaturityDate__c,
        Target.LastChangeDateTime__c = Source.LastChangeDateTime__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        TtlSchPymts__c,
        InvPymtsAmount__c,
        UninvPymtsAmount__c,
        FirstPayment__c,
        NextPayment__c,
        MaturityDate__c,
        LastChangeDateTime__c,
        LastChangeOperator__c
    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.TtlSchPymts__c,
        Source.InvPymtsAmount__c,
        Source.UninvPymtsAmount__c,
        Source.FirstPayment__c,
        Source.NextPayment__c,
        Source.MaturityDate__c,
        Source.LastChangeDateTime__c,
        Source.LastChangeOperator__c
    );