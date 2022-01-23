SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create   proc [dbo].[GetUnUsedJobs]
as
INSERT INTO LW_Monitor.[dbo].[JobInfo]
([Name]
,[UserFriendlyName]
,[IsActive])
select c.Name, c.UserFriendlyName,c.IsActive from JobTaskConfigs c
where c.ID not in (select distinct TaskId from JobSteps)

GO
