SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlanBasisAdministrativeCharges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[MinimumTransaction_Amount] [decimal](16, 2) NOT NULL,
	[MinimumTransaction_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaximumTransaction_Amount] [decimal](16, 2) NOT NULL,
	[MaximumTransaction_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdministrativeCost_Amount] [decimal](16, 2) NOT NULL,
	[AdministrativeCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[COFAdjustment] [decimal](9, 5) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlanBaseId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlanBasisAdministrativeCharges]  WITH CHECK ADD  CONSTRAINT [EPlanBase_PlanBasisAdministrativeCharges] FOREIGN KEY([PlanBaseId])
REFERENCES [dbo].[PlanBases] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PlanBasisAdministrativeCharges] CHECK CONSTRAINT [EPlanBase_PlanBasisAdministrativeCharges]
GO
