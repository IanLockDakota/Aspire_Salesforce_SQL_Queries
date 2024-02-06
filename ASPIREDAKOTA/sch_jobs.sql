--first detach--
EXEC [dbo].[sp_detach_schedule]
	@job_name = 'ASPIRDAKOTA_Payment_Pull',
	@schedule_name = '2.5min';

EXEC [dbo].[sp_detach_schedule]
	@job_name = 'ASPIREDAKOTA_EFTAltSchedule_Pull',
	@schedule_name = '2.5min';

EXEC [dbo].[sp_detach_schedule]
	@job_name = 'ASPIREDAKOTA_Invoice_Pull',
	@schedule_name = '2.5min';

--first add--
EXEC [dbo].[sp_add_jobschedule]
	@job_name = 'ASPIRDAKOTA_Payment_Pull',
	@name = '15min';

EXEC [dbo].[sp_add_jobschedule]
	@job_name = 'ASPIREDAKOTA_EFTAltSchedule_Pull',
	@name = '15min';

EXEC [dbo].[sp_add_jobschedule]
	@job_name = 'test_sch_change',
	@name = '15min';


--second detach--
EXEC [dbo].[sp_detach_schedule]
	@job_name = 'ASPIRDAKOTA_Payment_Pull',
	@schedule_name = '15min';

EXEC [dbo].[sp_detach_schedule]
	@job_name = 'ASPIREDAKOTA_EFTAltSchedule_Pull',
	@schedule_name = '15min';

EXEC [dbo].[sp_detach_schedule]
	@job_name = 'ASPIREDAKOTA_Invoice_Pull',
	@schedule_name = '15min';

--second add--
EXEC [dbo].[sp_add_jobschedule]
	@job_name = 'ASPIRDAKOTA_Payment_Pull',
	@name = '2.5min';

EXEC [dbo].[sp_add_jobschedule]
	@job_name = 'test_sch_change',
	@name = '2.5min';

EXEC [dbo].[sp_add_jobschedule]
	@job_name = 'test_sch_change',
	@name = '2.5min';