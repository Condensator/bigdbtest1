SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetServices](
	[Id] [bigint] NOT NULL,
	[IsSimplAssistant] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ServiceStartDate] [date] NULL,
	[ServiceStopDate] [date] NULL,
	[GracePeriodInMonths] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[GracePeriodStopDate] [date] NULL,
	[IsFreeChangeOfTires] [bit] NOT NULL,
	[IsFreeAutobox] [bit] NOT NULL,
	[IsFreeInsuranceDamage] [bit] NOT NULL,
	[IsFreeReplacementCar] [bit] NOT NULL,
	[IsFreeAnnualTechnicalCheck] [bit] NOT NULL,
	[IsVignette] [bit] NOT NULL,
	[IsSBACard] [bit] NOT NULL,
	[NextAnnualTechnicalCheck] [date] NULL,
	[NextChangeOfTires] [date] NULL,
	[NextAutobox] [date] NULL,
	[NextVignetteRenew] [date] NULL,
	[NextSBACardRenew] [date] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetServices]  WITH CHECK ADD  CONSTRAINT [EAsset_AssetService] FOREIGN KEY([Id])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetServices] CHECK CONSTRAINT [EAsset_AssetService]
GO
