SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Branches](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BranchNumber] [bigint] NOT NULL,
	[BranchName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[VATRegistrationNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BranchCode] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CostCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreationDate] [date] NOT NULL,
	[ActivationDate] [date] NULL,
	[InActivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[IsHeadquarter] [bit] NOT NULL,
	[EIKNumber_CT] [varbinary](64) MASKED WITH (FUNCTION = 'default()') NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Branches]  WITH CHECK ADD  CONSTRAINT [EBranch_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Branches] CHECK CONSTRAINT [EBranch_LegalEntity]
GO
ALTER TABLE [dbo].[Branches]  WITH CHECK ADD  CONSTRAINT [EBranch_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Branches] CHECK CONSTRAINT [EBranch_Portfolio]
GO
