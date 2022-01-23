SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgencyLegalPlacementAmounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FundsReceived_Amount] [decimal](16, 2) NOT NULL,
	[FundsReceived_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[AgencyLegalPlacementId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AgencyLegalPlacementAmounts]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacement_AgencyLegalPlacementAmounts] FOREIGN KEY([AgencyLegalPlacementId])
REFERENCES [dbo].[AgencyLegalPlacements] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AgencyLegalPlacementAmounts] CHECK CONSTRAINT [EAgencyLegalPlacement_AgencyLegalPlacementAmounts]
GO
ALTER TABLE [dbo].[AgencyLegalPlacementAmounts]  WITH CHECK ADD  CONSTRAINT [EAgencyLegalPlacementAmount_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AgencyLegalPlacementAmounts] CHECK CONSTRAINT [EAgencyLegalPlacementAmount_Currency]
GO
