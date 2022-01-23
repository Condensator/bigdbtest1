SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsurancePolicyAssignmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[InsurancePolicyAssignmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsurancePolicyAssignmentDetails]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicyAssignment_InsurancePolicyAssignmentDetails] FOREIGN KEY([InsurancePolicyAssignmentId])
REFERENCES [dbo].[InsurancePolicyAssignments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InsurancePolicyAssignmentDetails] CHECK CONSTRAINT [EInsurancePolicyAssignment_InsurancePolicyAssignmentDetails]
GO
ALTER TABLE [dbo].[InsurancePolicyAssignmentDetails]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicyAssignmentDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicyAssignmentDetails] CHECK CONSTRAINT [EInsurancePolicyAssignmentDetail_Asset]
GO
