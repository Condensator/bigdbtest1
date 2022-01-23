SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertiesInformationForCreditDecisions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Property] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RelatedActs] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RegistryAgency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Location] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[m2] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreditDecisionForCreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertiesInformationForCreditDecisions]  WITH CHECK ADD  CONSTRAINT [ECreditDecisionForCreditApplication_PropertiesInformationForCreditDecisions] FOREIGN KEY([CreditDecisionForCreditApplicationId])
REFERENCES [dbo].[CreditDecisionForCreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PropertiesInformationForCreditDecisions] CHECK CONSTRAINT [ECreditDecisionForCreditApplication_PropertiesInformationForCreditDecisions]
GO
