SELECT
	c.contractOID,
	chen.entt_oid, 
	r.descr,
	e.name,
	e.legal_name,
	e.alt_name,
	cbtlloc.FullAddress AS BillToLocation,
	ctxloc.FullAddress AS TaxLocation,
	celoc.FullAddress AS CEBillToLocation,
	e.email_addr,
	ISNULL(ph.phone_type, NULL) AS phone_type,
	ISNULL(ph.phone_num, NULL) AS phone_num,
	ISNULL(ph.extension, NULL) AS extension,
	ph.is_primary AS "primary_phone",
	CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE e.CollectorOid END AS CollectorOID,
    CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE collector.name END AS CollectorName,
    CASE WHEN r.descr = 'Guarantor' THEN NULL ELSE e.PermanentCollectionAssignmentFlag END AS PermanentCollectionAssignmentFlag
FROM
	Contract c
	LEFT OUTER JOIN ChildEntity chen ON chen.ref_oid = c.contractOID
	LEFT OUTER JOIN role r ON r.oid = chen.role_oid
	LEFT OUTER JOIN Entity e ON chen.entt_oid = e.oid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			e.CollectorOid,
			e2.name
		FROM 
			Entity e
			LEFT OUTER JOIN Entity e2 ON e.collectorOID = e2.oid
		WHERE
			e2.name IS NOT NULL) AS collector ON e.collectorOID = collector.CollectorOid
	LEFT OUTER JOIN Phone ph ON chen.entt_oid = ph.entt_oid
	LEFT OUTER JOIN
		(SELECT 
			c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
		FROM 
			GenericField GF 
			LEFT OUTER JOIN cdataGenericValue GV ON GF.oid = GV.genf_oid 
			LEFT OUTER JOIN Contract c ON c.ContractOid = gv.ref_oid
		WHERE 
			GF.oid = 23
		GROUP BY 
			c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppID ON c.contractOID = OppID.ContractOid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			c.BillToLocationOid,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			contract c
			LEFT OUTER JOIN contractEquipment ce ON c.contractOID = ce.ContractOid
			LEFT OUTER JOIN Location loc ON c.BillToLocationOid = loc.oid) AS cbtlloc ON c.contractOID = cbtlloc.contractOID
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			c.TaxLocationOid,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			contract c
			LEFT OUTER JOIN Location loc ON c.TaxLocationOid = loc.oid) AS ctxloc ON c.contractOID = ctxloc.contractOID
	LEFT OUTER JOIN
		(SELECT DISTINCT
			c.contractOID,
			ce.BilltoLocationOid AS ceBillToLocationOID,
			CONCAT(loc.addr_line1, ISNULL(loc.addr_line2, ''), ', ', loc.city, ', ', loc.state, ' ', loc.postal_code) AS FullAddress
		FROM
			contract c
			LEFT OUTER JOIN contractEquipment ce ON c.contractOID = ce.ContractOid
			LEFT OUTER JOIN Location loc ON ce.BilltoLocationOid = loc.oid) AS celoc ON c.contractOID = celoc.contractOID
WHERE
	(chen.entt_OID <> 1) AND (r.descr <> 'Collector')
ORDER BY
	c.contractOID, r.descr