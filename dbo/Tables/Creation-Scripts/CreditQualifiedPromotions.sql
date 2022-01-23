SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditQualifiedPromotions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ProgramPromotionId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditQualifiedPromotions]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditQualifiedPromotions] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditQualifiedPromotions] CHECK CONSTRAINT [ECreditProfile_CreditQualifiedPromotions]
GO
ALTER TABLE [dbo].[CreditQualifiedPromotions]  WITH CHECK ADD  CONSTRAINT [ECreditQualifiedPromotion_ProgramPromotion] FOREIGN KEY([ProgramPromotionId])
REFERENCES [dbo].[ProgramPromotions] ([Id])
GO
ALTER TABLE [dbo].[CreditQualifiedPromotions] CHECK CONSTRAINT [ECreditQualifiedPromotion_ProgramPromotion]
GO
