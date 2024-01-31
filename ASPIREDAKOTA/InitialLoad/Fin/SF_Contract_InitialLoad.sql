MERGE INTO Contract_ASPIRE__c_upsert AS Target
USING (SELECT
    NULL as ID,
	c.ContractOID AS ContractOID__c,
	OppIDTable.opportunityID AS OpportunityID__c,
	TC.Description AS TransactionCode__c,
	ic.Description AS InvoiceCode__c,
	c.IsSuspendInvoice AS IsSuspendInvoice__c,
	c.ImplicitRate AS ImplicitRate__c,
    ct.InternalYieldRate AS InternalYieldRate__c,
	ild.Description as InvoiceLeadDays__c,
	tt.descr as TaxTreatment__c,
    cac.Description as CashApplication__C,
	c.IsNonAccrual as IsNonAccrual__c,
	c.NonAccrualEffectiveDate as NonAccrualEffectiveDate__c,
	c.IsTerminated as IsTerminated__c,
	c.TerminationDate as TerminationDate__c,
	c.LastChangeOperator as LastChangeOperator__c,
	c.LastChangeDateTime as LastChangeDateTime__c
FROM
	Contract c
	LEFT OUTER JOIN
		(SELECT *
		FROM 
			LTIValues
		WHERE 
			table_key = 'FINANCE_PROGRAMS') as program ON c.ProgramOid = program.oid
	LEFT OUTER JOIN TransactionCode tc ON c.TransactionCodeOid = tc.TransactionCodeOid
	LEFT OUTER JOIN InvoiceCode ic ON c.InvoiceCodeOid = ic.InvoiceCodeOid
    LEFT OUTER JOIN ContractTerm ct ON c.ContractOid = CT.ContractOid
	LEFT OUTER JOIN
		(SELECT
			*
		FROM
			Status
		WHERE status_type = 'CONTRACT') AS status ON c.StatusOid = status.oid
	LEFT OUTER JOIN InvoiceLeadDays ild ON c.InvoiceLeadDaysOid = ild.InvoiceLeadDaysOid
	LEFT OUTER JOIN
		(SELECT *
		FROM 
			LTIValues
		WHERE 
			table_key = 'CONTRACT_TYPE2') as ct2 ON c.ContractType2Oid = ct2.oid
	LEFT OUTER JOIN
		(SELECT *
		FROM 
			LTIValues
		WHERE 
			table_key = 'CompoundingPeriod') as compound ON c.CompoundingPeriod = compound.data_value
	LEFT OUTER JOIN
		(SELECT *
		FROM 
			LTIValues
		WHERE 
			table_key = 'TAX_TREATMENT') as tt ON c.TaxTreatment = tt.data_value
    LEFT OUTER JOIN CashApplicationCode cac ON c.CashApplicationCodeOid = cac.CashApplicationCodeOid
	LEFT OUTER JOIN
		(SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
			FROM GenericField GF 
            LEFT OUTER JOIN cdataGenericValue GV ON GF.oid = GV.genf_oid
            LEFT OUTER JOIN Contract c ON c.ContractOid = gv.ref_oid
            WHERE GF.oid = 23
            GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIDTable ON c.ContractOid = OppIDTable.ContractOID
WHERE
	(OppIDTable.opportunityID IS NOT NULL)) AS source ON Target.ContractOID__c = Source.ContractOID__c


/*Upsert capabilities*/

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.OpportunityID__c,
        Target.TransactionCode__c = Source.TransactionCode__c,
        Target.InvoiceCode__c = Source.InvoiceCode__c,
        Target.IsSuspendInvoice__c = Source.IsSuspendInvoice__c,
        Target.ImplicitRate__c = Source.ImplicitRate__c,
        Target.InternalYieldRate__c = Source.InternalYieldRate__c,
        Target.InvoiceLeadDays__c = Source.InvoiceLeadDays__c,
        Target.TaxTreatment__c = Source.TaxTreatment__c,
        Target.CashApplication__C = Source.CashApplication__C,
        Target.IsNonAccrual__c = Source.IsNonAccrual__c,
        Target.NonAccrualEffectiveDate__c = Source.NonAccrualEffectiveDate__c,
        Target.IsTerminated__c = Source.IsTerminated__c,
        Target.TerminationDate__c = Source.TerminationDate__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c,
        Target.LastChangeDateTime__c = Source.LastChangeDateTime__c


WHEN NOT MATCHED THEN
    INSERT (
        ID,
        ContractOID__c,
        OpportunityID__c,
        TransactionCode__c,
        InvoiceCode__c,
        IsSuspendInvoice__c,
        ImplicitRate__c,
        InternalYieldRate__c,
        InvoiceLeadDays__c,
        TaxTreatment__c,
        CashApplication__C,
        IsNonAccrual__c,
        NonAccrualEffectiveDate__c,
        IsTerminated__c,
        TerminationDate__c,
        LastChangeOperator__c,
        LastChangeDateTime__c


    ) VALUES (
        Source.ID,
        Source.ContractOID__c,
        Source.OpportunityID__c,
        Source.TransactionCode__c,
        Source.InvoiceCode__c,
        Source.IsSuspendInvoice__c,
        Source.ImplicitRate__c,
        Source.InternalYieldRate__c,
        Source.InvoiceLeadDays__c,
        Source.TaxTreatment__c,
        Source.CashApplication__C,
        Source.IsNonAccrual__c,
        Source.NonAccrualEffectiveDate__c,
        Source.IsTerminated__c,
        Source.TerminationDate__c,
        Source.LastChangeOperator__c,
        Source.LastChangeDateTime__c

        );

