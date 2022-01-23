SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlanPayoutOptionVolumeTiers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[MinimumVolume_Amount] [decimal](16, 2) NOT NULL,
	[MinimumVolume_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaximumVolume_Amount] [decimal](16, 2) NOT NULL,
	[MaximumVolume_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Commission] [decimal](9, 5) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlanBasesPayoutId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlanPayoutOptionVolumeTiers]  WITH CHECK ADD  CONSTRAINT [EPlanBasesPayout_PlanPayoutOptionVolumeTiers] FOREIGN KEY([PlanBasesPayoutId])
REFERENCES [dbo].[PlanBasesPayouts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PlanPayoutOptionVolumeTiers] CHECK CONSTRAINT [EPlanBasesPayout_PlanPayoutOptionVolumeTiers]
GO
