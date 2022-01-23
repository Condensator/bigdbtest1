SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FloatRateIndexDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BaseRate] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsModified] [bit] NOT NULL,
	[IsRateUsed] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FloatRateIndexId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FloatRateIndexDetails]  WITH CHECK ADD  CONSTRAINT [EFloatRateIndex_FloatRateIndexDetails] FOREIGN KEY([FloatRateIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FloatRateIndexDetails] CHECK CONSTRAINT [EFloatRateIndex_FloatRateIndexDetails]
GO
