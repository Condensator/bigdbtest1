SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsurancePolicyAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PrivateLabelEntityName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[InsurancePolicyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsurancePolicyAssignments]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_InsurancePolicyAssignments] FOREIGN KEY([InsurancePolicyId])
REFERENCES [dbo].[InsurancePolicies] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InsurancePolicyAssignments] CHECK CONSTRAINT [EInsurancePolicy_InsurancePolicyAssignments]
GO
ALTER TABLE [dbo].[InsurancePolicyAssignments]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicyAssignment_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicyAssignments] CHECK CONSTRAINT [EInsurancePolicyAssignment_Contract]
GO
