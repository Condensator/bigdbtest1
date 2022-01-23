SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeEnMasseUpdateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmployeeAssignedToPartyId] [bigint] NOT NULL,
	[EmployeeEnMasseUpdateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EEmployeeEnMasseUpdate_EmployeeEnMasseUpdateDetails] FOREIGN KEY([EmployeeEnMasseUpdateId])
REFERENCES [dbo].[EmployeeEnMasseUpdates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdateDetails] CHECK CONSTRAINT [EEmployeeEnMasseUpdate_EmployeeEnMasseUpdateDetails]
GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [EEmployeeEnMasseUpdateDetail_EmployeeAssignedToParty] FOREIGN KEY([EmployeeAssignedToPartyId])
REFERENCES [dbo].[EmployeesAssignedToParties] ([Id])
GO
ALTER TABLE [dbo].[EmployeeEnMasseUpdateDetails] CHECK CONSTRAINT [EEmployeeEnMasseUpdateDetail_EmployeeAssignedToParty]
GO
