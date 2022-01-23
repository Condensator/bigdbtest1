SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetsValueStatusChanges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Reason] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsZeroMode] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SourceModule] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[SourceModuleId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[ReversalPostDate] [date] NULL,
	[MigrationId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetsValueStatusChanges]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChange_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChanges] CHECK CONSTRAINT [EAssetsValueStatusChange_Currency]
GO
ALTER TABLE [dbo].[AssetsValueStatusChanges]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChange_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChanges] CHECK CONSTRAINT [EAssetsValueStatusChange_LegalEntity]
GO
