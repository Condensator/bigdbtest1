SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RegistrationHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrationCertificateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DateOfRegistration] [date] NULL,
	[DeliveredOn] [date] NULL,
	[IsActive] [bit] NULL,
	[EngineNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveFromDate] [date] NULL,
	[EffectiveTillDate] [date] NULL,
	[PreviousLeaseAgreement] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RegistrationHistories]  WITH CHECK ADD  CONSTRAINT [EAsset_RegistrationHistories] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RegistrationHistories] CHECK CONSTRAINT [EAsset_RegistrationHistories]
GO
